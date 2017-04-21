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

require_relative 'l10n/asset'
require_relative 'l10n/data_downloader'
require_relative 'l10n/script_downloader'

module ReleaseMe
  # FIXME: doesn't write master cmake right now...
  class L10n < TranslationUnit
    prepend Logable

    RELEASEME_TEST_DIR = File.absolute_path("#{__dir__}/../../test").freeze

    def get(srcdir, target = File.expand_path("#{srcdir}/po"),
            qttarget = File.expand_path("#{target}/../poqm"), edit_cmake: true)
      Dir.mkdir(target)
      Dir.mkdir(qttarget)

      @templates = find_templates(srcdir)
      log_info "Downloading translations for #{srcdir}"

      languages_without_translation = []
      # FIXME: due to threading we do explicit pathing, so this probably can go
      Dir.chdir(srcdir) do
        # FIXME: languages_without_translation is super naughty here. it is
        #   filled by reference inside threads... super shit not thread safe
        download(srcdir, languages_without_translation, target, qttarget)
        post_process(target, qttarget, edit_cmake)
      end

      return if languages_without_translation.empty?
      print_missing_languages(languages_without_translation)
    end

    private

    def blocking_thread_pool
      threads = THREAD_COUNT.times.collect do
        Thread.new do
          Thread.current.abort_on_exception = true
          yield
        end
      end
      ThreadsWait.all_waits(threads)
    end

    def each_language_with_tmpdir(queue = languages_queue)
      blocking_thread_pool do
        until queue.empty?
          begin
            lang = queue.pop(true)
          rescue
            # When pop runs into an empty queue with non_block=true it raises
            # an exception. We'll simply continue with it as our loop should
            # naturally end anyway.
            continue
          end
          Dir.mktmpdir(self.class.to_s) { |tmpdir| yield lang, tmpdir }
        end
      end
    end

    def download(srcdir, languages_without_translation, target, qttarget)
      script_cache = L10nScriptDownloader::TemplateCache.new(self)
      each_language_with_tmpdir do |lang, tmpdir|
        log_debug "#{srcdir} - downloading #{lang}"
        files = []

        # Data assets are not linked to a template, so we can run these
        # before even looking at the templates in detail.
        files += L10nDataDownloader.new(lang, tmpdir, self).download

        if templates.count > 1
          files += get_multiple(lang, tmpdir)
        elsif templates.count == 1
          files += get_single(lang, tmpdir)
        end
        # No translations need fetching. But continue because not
        # all assets are template bound.

        files += L10nScriptDownloader.new(lang, tmpdir, script_cache,
                                          self).download

        files = files.compact.uniq

        # No files obtained :(
        if files.empty?
          # FIXME: not thread safe without GIL
          languages_without_translation << lang
          next
        end

        # TODO: path confusing with target
        files.each do |file|
          file = L10nAsset.new(file)
          file.strip!
          destination = if file.qt? && !kde4_origin?
                          "#{qttarget}/#{lang}"
                        else
                          "#{target}/#{lang}"
                        end
          FileUtils.mkpath(destination)
          FileUtils.mv(file, destination)
        end

        # FIXME: this is not thread safe without a GIL
        @languages += [lang]
      end
    end

    def post_process(target, qttarget, edit_cmake)
      if ENV.include?('RELEASEME_L10N_REQUIREMENT')
        completion_requirement = ENV['RELEASEME_L10N_REQUIREMENT'].to_i
        require_relative 'l10nstatistics'
        [target, qttarget].each do |dir|
          stats = L10nStatistics.new.tap { |l| l.gather!(dir) }.stats
          stats.each do |lang, stat|
            next if stat[:percentage] >= completion_requirement
            FileUtils.rm_r("#{dir}/#{lang}", verbose: true)
          end
        end
      end

      # Update Data after mangling

      po_files = Dir.glob("#{target}/**/**")
      po_files.select! { |x| File.file?(x) }

      qt_files = Dir.glob("#{qttarget}/**/**")
      qt_files.select! { |x| File.file?(x) }

      has_po_translations = !po_files.empty?
      has_qt_translations = !qt_files.empty?

      if has_po_translations
        if edit_cmake
          # Update master CMakeLists.txt
          # FIXME: Dir.pwd because we chdir above and never undo that.
          CMakeEditor.append_po_install_instructions!(Dir.pwd, 'po')
        end

        # Create po's CMakeLists.txt if there are data assets we need to
        # install. Data assets rely on CMakeLists.txt supplied by
        # translators, we still need to assemble the directories with assets
        # into the po/CMakeLists.txt though.
        data_assets = Dir.glob("#{target}/*/data/*")
        unless data_assets.empty?
          File.open("#{target}/CMakeLists.txt", 'a') do |f|
            data_assets.each do |dir|
              f.puts(CMakeEditor.add_subdirectory(dir, relative_to: target))
            end
          end
          if edit_cmake
            # FIXME: Dir.pwd because we chdir above and never undo that.
            CMakeEditor.append_optional_add_subdirectory!(Dir.pwd, 'po')
          end
        end

        # cmake_modules may be used by data assets, they are meant to be
        # folded into a join cmake_modules dir (doesn't make sense to me
        # why though, seems to me that does nothing but cause risk of clash)
        mod_target = "#{target}/cmake_modules".freeze
        Dir.glob("#{target}/*/cmake_modules").each do |mod|
          content = Dir.glob("#{mod}/*").reject { |x| x.include?('.svn') }
          FileUtils.mkpath(mod_target)
          FileUtils.cp_r(content, mod_target, verbose: true)
          FileUtils.rm_r(mod)
        end
      end

      # Process Qt translations. This MUST be after the PO translations as
      # we may wish to reuse the PO location if there's only Qt translations.
      if has_qt_translations
        final_target = qttarget # Can get modified.

        unless has_po_translations
          log_info 'Found Qt translations, but no Gettext translations.' \
                   ' Storing Qt translations in po/ dir.'
          FileUtils.rm_r(target)
          FileUtils.mv(qttarget, target)
          # Prevent us from getting deleted in the new target.
          has_po_translations = has_qt_translations
          final_target = target
        end

        if edit_cmake
          # Update master CMakeLists.txt
          # FIXME: handle *name in CMakeEditor, this is way too long a line.
          CMakeEditor
            .append_poqm_install_instructions!(File.dirname(final_target),
                                               File.basename(final_target))
        end
      end

      # Remove the empty translations directory
      Dir.delete(target) unless has_po_translations
      Dir.delete(qttarget) unless has_qt_translations
    end

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
      files << po_file_path if File.exist?(po_file_path)
      files
    end

    def get_multiple(lang, tmpdir)
      vcs_path = po_file_dir(lang)

      return [] if @vcs.list(vcs_path).empty?
      @vcs.get(tmpdir, vcs_path)

      files = templates.collect do |po|
        po_file_path = tmpdir.dup.concat("/#{po}")
        next nil unless File.exist?(po_file_path)
        po_file_path if File.exist?(po_file_path)
      end

      files
    end

    def kde4_origin?
      ReleaseMe::Origin.kde4?(type)
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
