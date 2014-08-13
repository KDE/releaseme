#--
# Copyright (C) 2007-2014 Harald Sitter <apachelogger@ubuntu.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License or (at your option) version 3 or any later version
# accepted by the membership of KDE e.V. (or its successor approved
# by the membership of KDE e.V.), which shall act as a proxy
# defined in Section 14 of version 3 of the license.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require 'fileutils'

require_relative 'cmakeeditor'
require_relative 'source'
require_relative 'svn'

# FIXME: doesn't write master cmake right now...
class KdeL10n < Source
    # The VCS to use to obtain the l10n sources
    attr :vcs, false
    # The type of the release (stable,trunk)
    attr :type, false
    # The application's module (used to build the checkout path - e.g. extragear)
    attr :module, false
    # The application's section within the module (e.g. multimedia for amarok)
    # Can be empty
    attr :section, false

    # Obtained and valid languages
    attr :languages, false
    # Found templates
    attr :templates, false

    # Type identifiers
    TRUNK  = :trunk
    STABLE = :stable

    def initialize(type, module_, section = "", vcs = nil)
        if vcs.nil?
            @vcs = Svn.new()
        else
            @vcs = vcs
        end

        if type.nil?
            raise "Type cannot be nil"
        else
            @type = type
        end

        if module_.nil?
            raise "Module cannot be nil"
        else
            @module = module_
        end

        if section.nil?
            raise "Section cannot be nil, but an empty string"
        else
            @section = section
        end

        @languages = Array.new
        @templates = Array.new

        initRepoUrl("svn://anonsvn.kde.org/home/kde/")
    end

    def initRepoUrl(baseUrl)
        repoUrl = baseUrl
        repoUrl.concat("/") if not repoUrl.end_with?("/")
        if type == TRUNK
            repoUrl.concat("trunk/")
        else
            repoUrl.concat("branches/stable/")
        end
        repoUrl.concat("/l10n-kf5/")

        @vcs.repository = repoUrl
    end

    def find_templates(directory, pos=Array.new)
        Dir.glob("#{directory}/**/**/Messages.sh").each do |file|
            File.readlines(file).each do |line|
                line.match(/[^\/]*\.pot/).to_a.each do |match|
                    pos << match.sub(".pot",".po")
                end
            end
        end
        # Templates must be unique as multiple lines can contribute to the same
        # template, as such it can happen that a.pot appears twice which can
        # have unintended consequences by an outside user of the Array.
        return pos.uniq
    end

    # FIXME: this has no test backing right now
    def strip_comments(file)
        # Strip #~ lines, which once were sensible translations, but then the
        # strings got removed, so they now stick around in case the strings
        # return, poor souls, waiting for a comeback, reminds me of Sunset Blvd :(
        # Problem is that msgfmt adds those to the binary!
        file = File.new(file, File::RDWR)
        str = file.read
        file.rewind
        file.truncate(0)
        # Sometimes a fuzzy marker can precede an obsolete translation block, so
        # first remove any fuzzy obsoletion in the file and then remove any
        # additional obsoleted lines.
        # This prevents the fuzzy markers from getting left over.
        str.gsub!(/^#, fuzzy\n#~.*/, '')
        str.gsub!(/^#~.*/, '')
        str = str.strip
        file << str
        file.close
    end

    def po_file_dir(lang)
        return "#{lang}/messages/#{@module}-#{@section}"
    end

    def retry_cmd?(exit_code, thing)
        if exit_code != 0
            return false
            raise "dialog not implemented"
            #retry_ = $dlg.yesnocancel("Fetching of #{thing} failed.", "Retry", "Skip")
            puts retry_
            exit 1 if retry_.nil?
            return retry_
        end
        return false
    end

    def get_single(lang)
        tempDir = "l10n"
        FileUtils.rm_rf(tempDir)
        Dir.mkdir(tempDir)

        # TODO: maybe class this
        poFileName = templates[0]
        vcsFilePath = "#{po_file_dir(lang)}/#{poFileName}"
        poFilePath = "#{tempDir}/#{poFileName}"

        gotInfo = false
        begin
            ret = vcs.export(poFilePath, vcsFilePath)
            # If the export failed, try to see if there is a file, if this command also
            # fails then we have to assume the file is not present in SVN.
            # Of course it still might, but the connection could be busted, but that
            # is a lot less likely to be the case for 2 independent commands.
            if not gotInfo and not ret
                # If the info also failed, declare the file as not existent and
                # prevent a retry dialog annoyance.
                break if not vcs.exist?(vcsFilePath)
                gotInfo = true
            end
        end while retry_cmd?(ret, "#{vcsFilePath}")

        files = Array.new
        if File.exist?(poFilePath)
            files << poFilePath
            strip_comments(poFilePath)
        end
        return files.uniq
    end

    def get_multiple(lang)
        tempDir = "l10n"
        FileUtils.rm_rf(tempDir)
        Dir.mkdir(tempDir)

        vcsDirPath = po_file_dir(lang)

        return Array.new if vcs.list(vcsDirPath).empty?
        begin
            ret = vcs.get(tempDir, vcsDirPath)
        end while retry_cmd?($?, vcsDirPath)

        files = Array.new
        templates.each do |po|
            poFilePath = tempDir.dup.concat("/#{po}")
            next if not File.exist?(poFilePath)
            files << poFilePath
            strip_comments(poFilePath)
        end
        return files.uniq
    end

    def get(sourceDirectory)
        previous_pwd = Dir.pwd
        target = sourceDirectory + "/po/"
        Dir.mkdir(target)

        availableLanguages = vcs.cat("subdirs").split("\n")
        @templates = find_templates(sourceDirectory)

        Dir.chdir(sourceDirectory) do
            availableLanguages.each do | language |
                next if language == 'x-test'

                puts "Downloading #{language} translations for #{sourceDirectory}"
                if templates.count > 1
                    files = get_multiple(language)
                elsif templates.count == 1
                    files = get_single(language)
                else
                    # FIXME: needs testcase
                    return # No translations need fetching
                end

                # No files obtained :(
                if files.empty?
                    puts '  got no translations, skipping.'
                    next
                end

                # TODO: path confusing with target
                destinationDir = "po/" + language
                Dir.mkdir(destinationDir)
                FileUtils.mv(files, destinationDir)
                #mv( ld + "/.svn", dest ) if $options[:tag] # Must be fatal iff tagging

                CMakeEditor::create_language_specific_po_lists!(destinationDir, language)

                # add to SVN in case we are tagging
                #%x[svn add #{dest}/CMakeLists.txt] if $ptions[:tag]
                @languages += [language]
            end
            # Make sure the temp dir is cleaned up
            FileUtils::rm_rf('l10n')
            # Update CMakeLists.txt
            CMakeEditor::create_po_meta_lists!('po/')
            CMakeEditor::append_optional_add_subdirectory!(Dir.pwd, 'po')
        end
    end

end
