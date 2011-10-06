#--
# Copyright (C) 2007-2011 Harald Sitter <apachelogger@ubuntu.com>
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

class Vcs
    # The repository URL
    attr :repository, true

    def get(target)
        raise "Pure virtual"
    end
end

class Git < Vcs
    # Clones repository into target directory
    # @param shallow whether or not to create a shallow clone
    def get(target, shallow = true)
        if (shallow)
            system("git clone --depth 1 #{repository} #{target}")
        else
            system("git clone #{repository} #{target}")
        end
    end
end

class Svn < Vcs
    # Svn checkout
    # @param target is the target directory for the checkout
    # @param path is an additional path to append to the repo URL
    # @returns boolean whether the checkout was successful
    def get(target, path = nil)
        url = repository.dup # Deep copy since we will patch around
        if not path.nil? and not path.empty?
            url.concat("/#{path}")
        end
        return system("svn co #{url} #{target}")
    end

    # Svn ls
    # @param path a path to append to the repository url (if any)
    # @returns output of ls command
    def list(path = nil)
        url = repository.dup # Deep copy since we will patch around
        if not path.nil? and not path.empty?
            url.concat("/#{path}")
        end
        return %x[svn ls #{url}]
    end

    # Svn cat
    # @param filePath filepath to append to the repository URL
    # @returns content of cat'd file as string
    def cat(filePath)
        return %x[svn cat #{repository}/#{filePath}]
    end

    # Svn export
    # @param filePath filepath to append to the repository URL
    # @param targetFilePath target file path to write to
    # @returns boolean whether or not the export was successful
    def export(filePath, targetFilePath)
        puts "svn export #{repository}/#{filePath} #{targetFilePath}"
        return system("svn export #{repository}/#{filePath} #{targetFilePath}")
    end

    # Checks whether a file/dir exists on the remote repository
    # @param filePath filepath to append to the repository URL
    # @returns boolean whether or not the path exists
    def exists?(filePath)
        return system("svn info #{repository}/#{filePath}")
    end
end

require 'fileutils'
class Source
    # The target directory
    attr :target, true

    # Cleans up data created
    def cleanup()
        FileUtils.rm_rf(target)
    end

    # Gets the source
    def get(vcs)
        vcs.get(target)
    end
end

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
    end

    def find_templates(directory, pos=Array.new)
        Dir.glob("#{directory}/**/**/Messages.sh").each do |file|
            File.readlines(file).each do |line|
                line.match(/[^\/]*\.pot/).to_a.each do |match|
                    pos << match.sub(".pot",".po")
                end
            end
        end
        return pos
    end

    def strip_comments(file)
        # Strip #~ lines, which once were sensible translations, but then the
        # strings become removed, so they now stick around in case the strings
        # return, poor souls, waiting for a comeback, reminds me of Sunset Blvd :(
        # Problem is that msgfmt adds those to the binary!
        file = File.new(file, File::RDWR)
        str = file.read
        file.rewind
        file.truncate(0)
        str.gsub!(/#~.*/, "")
        str = str.strip
        file << str
        file.close
    end

    def pofiledir?(lang)
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
        puts "get single #{lang}"
        tempDir = "l10n"
        FileUtils.rm_rf(tempDir)
        Dir.mkdir(tempDir)

        pofilename = templates[0]
        vcsFilePath = "#{pofiledir?(lang)}/#{pofilename}"

        gotInfo = false
        begin
            ret = vcs.export(vcsFilePath, poFilePath)
            # If the export failed, try to see if there is a file, if this command also
            # fails then we have to assume the file is not present in SVN.
            # Of course it still might, but the connection could be busted, but that
            # is a lot less likely to be the case for 2 independent commands.
            if not gotInfo and not ret
                # If the info also failed, declare the file as not existent and
                # prevent a retry dialog annoyance.
                break if not vcs.exists?(vcsFilePath)
                gotInfo = true
            end
        end while retry_cmd?(ret, "#{vcsFilePath}")

        files = Array.new
        if File.exist?(poFilePath)
            files << poFilePath
            strip_comments(poFilePath)
        end
        return files
    end

    def get_multiple(lang)
        puts "get multi #{lang}"
        tempDir = "l10n"
        FileUtils.rm_rf(tempDir)
        Dir.mkdir(tempDir)

        vcsDirPath = pofiledir?(lang)

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
        return files
    end

    def get(sourceDirectory)
        repo = "svn://anonsvn.kde.org/home/kde/"
        if type == TRUNK
            repo.concat("trunk/")
        else
            repo.concat("branches/stable/")
        end
        repo.concat("/l10n-kde4/")

        vcs.repository = repo
        target = sourceDirectory + "/po/"
        Dir.mkdir(target)

        availableLanguages = vcs.cat("subdirs").split("\n")
        @templates = find_templates(sourceDirectory)

        # TODO: fix chdiring to something better
        Dir.chdir(sourceDirectory)
        availableLanguages.each { | language |
            next if language == "x-test"

            if templates.count > 1
                files = get_multiple(language)
            else
                files = get_single(language)
            end

            p "FILESS"
            p files
            # No files obtained :(
            next if files.empty?

            puts("Copying #{language}\'s .po(s) over ...")
            # TODO: path confusing with target
            destinationDir = "po/" + language
            Dir.mkdir(destinationDir)
            FileUtils.mv(files, destinationDir)
            #mv( ld + "/.svn", dest ) if $options[:tag] # Must be fatal iff tagging

            cmakefile = File.new( "#{destinationDir}/CMakeLists.txt", File::CREAT | File::RDWR | File::TRUNC )
            cmakefile << "file(GLOB _po_files *.po)\n"
            cmakefile << "GETTEXT_PROCESS_PO_FILES(#{language} ALL INSTALL_DESTINATION ${LOCALE_INSTALL_DIR} ${_po_files} )\n"
            cmakefile.close

            # add to SVN in case we are tagging
            #%x[svn add #{dest}/CMakeLists.txt] if $options[:tag]
            @languages += [language]

            puts "done."
        }
        Dir.chdir("..")
    end
end

class XzArchive
    # The directory to archive
    attr :directory, true

    # XZ compression level
    attr :level, true

    def initialize()
        @directory = nil
        @level = 9
    end

    # Create the archive
    def create()
        tar = "#{directory}.tar"
        begin
            raise RuntimeError if not system("tar -cf #{tar} #{directory}")
            raise RuntimeError if not system("xz -#{level} #{tar}")
        rescue
            FileUtils.rm_rf(tar)
            FileUtils.rm_rf(tar + ".xz")
        end
    end
end

class KdeGitRelease
    # The vcs from which to get the source
    attr_reader :vcs
    # The source object from which the release is done
    attr_reader :source
    # The archive object which will create the archive
    attr_reader :archive

    # Init
    def initialize()
        @vcs = Git.new()
        @source = Source.new()
        @archive = XzArchive.new()
    end

    # Get the source
    def get()
        source.cleanup()
        source.get(vcs)
    end

    # Create the final archive file
    def archive()
        @archive.directory = source.target
        @archive.create()
    end

end
