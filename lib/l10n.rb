#--
# Copyright (C) 2007-2015 Harald Sitter <apachelogger@ubuntu.com>
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
require 'tmpdir'

require_relative 'cmakeeditor'
require_relative 'logable'
require_relative 'source'
require_relative 'svn'
require_relative 'translationunit'

# FIXME: doesn't write master cmake right now...
class L10n < TranslationUnit
  prepend Logable

  def find_templates(directory, pos = [])
    Dir.glob("#{directory}/**/**/Messages.sh").each do |file|
      File.readlines(file).each do |line|
        line.match(/[^\/]*\.pot/).to_a.each do |match|
          pos << match.sub('.pot','.po')
        end
      end
    end
    # Templates must be unique as multiple lines can contribute to the same
    # template, as such it can happen that a.pot appears twice which can
    # have unintended consequences by an outside user of the Array.
    pos.uniq
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
    "#{lang}/messages/#{@i18n_path}"
  end

  def get_single(lang, tmpdir)
    # TODO: maybe class this
    po_file_name = templates[0]
    vcs_file_path = "#{po_file_dir(lang)}/#{po_file_name}"
    po_file_path = "#{tmpdir}/#{po_file_name}"

    vcs.export(po_file_path, vcs_file_path)

    files = []
    if File.exist?(po_file_path)
      files << po_file_path
      strip_comments(po_file_path)
    end
    files.uniq
  end

  def get_multiple(lang, tmpdir)
    vcs_path = po_file_dir(lang)

    return [] if @vcs.list(vcs_path).empty?
    @vcs.get(tmpdir, vcs_path)

    files = []
    templates.each do |po|
      po_file_path = tmpdir.dup.concat("/#{po}")
      next unless File.exist?(po_file_path)
      files << po_file_path
      strip_comments(po_file_path)
    end

    files.uniq
  end

  def get(srcdir)
    target = "#{srcdir}/po/"
    Dir.mkdir(target)

    available_languages = vcs.cat('subdirs').split("\n")
    @templates = find_templates(srcdir)

    log_info "Downloading translations for #{srcdir}"

    languages_without_translation = []
    has_translation = false
    Dir.chdir(srcdir) do
      available_languages.each do |language|
        next if language == 'x-test'

        Dir.mktmpdir(self.class.to_s) do |tmpdir|
          log_debug "#{srcdir} - downloading #{language}"
          if templates.count > 1
            files = get_multiple(language, tmpdir)
          elsif templates.count == 1
            files = get_single(language, tmpdir)
          else
            # FIXME: needs testcase
            return # No translations need fetching
          end

          # No files obtained :(
          if files.empty?
            languages_without_translation << language
            next
          end
          has_translation = true

          # TODO: path confusing with target
          destination = "po/#{language}"
          Dir.mkdir(destination)
          FileUtils.mv(files, destination)
        end

        @languages += [language]
      end

      if has_translation
        # Update CMakeLists.txt
        CMakeEditor.append_po_install_instructions!(Dir.pwd, 'po')
      else
        # Remove the empty translations directory
        Dir.delete('po')
      end
    end

    return if languages_without_translation.empty?
    log_info "No translations for: #{languages_without_translation.join(', ')}"
  end
end
