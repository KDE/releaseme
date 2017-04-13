#--
# Copyright (C) 2007-2017 Harald Sitter <apachelogger@ubuntu.com>
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

require 'English'
require 'fileutils'
require 'thwait'
require 'tmpdir'

require_relative 'cmakeeditor'
require_relative 'logable'
require_relative 'source'
require_relative 'svn'
require_relative 'translationunit'

require_relative 'l10n/script_downloader'

module ReleaseMe
  # FIXME: doesn't write master cmake right now...
  class L10n < TranslationUnit
    prepend Logable

    RELEASEME_TEST_DIR = File.absolute_path("#{__dir__}/../../test").freeze

    def verify_pot(potname)
      return unless potname.include?('$')
      raise "l10n pot appears to be a variable. cannot resolve #{potname}"
    end

    def find_templates(directory, pos = [], skip_dir: RELEASEME_TEST_DIR)
      Dir.glob("#{directory}/**/**/Messages.sh").each do |file|
        next if skip_dir && File.absolute_path(file).start_with?(skip_dir)
        File.readlines(file).each do |line|
          line.match(%r{[^/\s=]+\.pot}).to_a.each do |match|
            verify_pot(match)
            pos << match.sub('.pot', '.po')
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

    def get(srcdir, target = File.expand_path("#{srcdir}/po"), edit_cmake: true)
      Dir.mkdir(target)

      @templates = find_templates(srcdir)
      log_info "Downloading translations for #{srcdir}"

      languages_without_translation = []
      has_translation = false
      # FIXME: due to threading we do explicit pathing, so this probably can go
      Dir.chdir(srcdir) do
        queue = languages_queue
        threads = []
        script_cache = L10nScriptDownloader::TemplateCache.new(self)
        THREAD_COUNT.times do
          threads << Thread.new do
            Thread.current.abort_on_exception = true
            until queue.empty?
              begin
                lang = queue.pop(true)
              rescue
                # When pop runs into an empty queue with non_block=true it raises
                # an exception. We'll simply continue with it as our loop should
                # naturally end anyway.
                continue
              end
              Dir.mktmpdir(self.class.to_s) do |tmpdir|
                log_debug "#{srcdir} - downloading #{lang}"
                files = []

                if templates.count > 1
                  files += get_multiple(lang, tmpdir)
                elsif templates.count == 1
                  files += get_single(lang, tmpdir)
                else
                  # FIXME: needs testcase
                  # TODO: this previously aborted entirely, not sure that makes
                  #       sense with threading
                  next # No translations need fetching
                end

                files += L10nScriptDownloader.new(lang, tmpdir, script_cache,
                                                  self).download

                # No files obtained :(
                if files.empty?
                  # FIXME: not thread safe without GIL
                  languages_without_translation << lang
                  next
                end
                # FIXME: not thread safe without GIL
                has_translation = true

                # TODO: path confusing with target
                destination = "#{target}/#{lang}"
                Dir.mkdir(destination)
                FileUtils.mv(files, destination)
              end

              # FIXME: this is not thread safe without a GIL
              @languages += [lang]
            end
          end
        end
        ThreadsWait.all_waits(threads)

        if ENV.include?('RELEASEME_L10N_REQUIREMENT')
          completion_requirement = ENV['RELEASEME_L10N_REQUIREMENT'].to_i
          require_relative 'l10nstatistics'
          stats = L10nStatistics.new.tap { |l| l.gather!(target) }.stats
          drop = stats.delete_if { |_, s| s[:percentage] >= completion_requirement }
          drop.each { |lang, _| FileUtils.rm_r("#{target}/#{lang}", verbose: true) }
          has_translation = false if Dir.glob("#{target}/*").empty?
        end

        if has_translation && edit_cmake
          # Update CMakeLists.txt
          CMakeEditor.append_po_install_instructions!(Dir.pwd, 'po')
        elsif !has_translation
          # Remove the empty translations directory
          Dir.delete('po')
        end
      end

      return if languages_without_translation.empty?
      print_missing_languages(languages_without_translation)
    end

    def print_missing_languages(missing)
      if (languages - missing).empty?
        path = po_file_dir('$lang')
        log_warn "!!! No translations found at SVN path #{path} !!!"
        log_warn "Looked for templates: #{@templates}"
      else
        log_info "No translations for: #{missing.join(', ')}"
      end
    end
  end
end
