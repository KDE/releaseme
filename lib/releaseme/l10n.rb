# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2007-2021 Harald Sitter <sitter@kde.org>

require 'English'
require 'fileutils'
require 'tmpdir'

require_relative 'cmakeeditor'
require_relative 'l10n_statistics'
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

    attr_reader :zero_percent_dropped
    attr_reader :statistics

    RELEASEME_TEST_DIR = File.absolute_path("#{__dir__}/../../test").freeze

    def get(srcdir, target = File.expand_path("#{srcdir}/po"),
            qttarget = File.expand_path("#{target}/../poqm"), edit_cmake: true)
      languages_without_translation = []

      if any_target_exists?(srcdir, target, qttarget)
        Dir.chdir(srcdir) do
          post_process(target, qttarget, false)
        end
        return
      end

      Dir.mkdir(target)
      Dir.mkdir(qttarget)

      log_info "Downloading translations for #{srcdir}"

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

    def download(srcdir, languages_without_translation, target, qttarget)
      each_language_with_tmpdir do |lang, tmpdir|
        log_debug "#{srcdir} - downloading #{lang}"
        files = []

        # Data assets are not linked to a template, so we can run these
        # before even looking at the templates in detail.
        files += L10nDataDownloader.new(lang, tmpdir, self).download

        files += get_messages(lang, tmpdir)
        # No translations need fetching. But continue because not
        # all assets are template bound.

        files += L10nScriptDownloader.new(lang, tmpdir, self).download

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
      @zero_percent_dropped = []
      @statistics = L10nStatistics.new([target, qttarget])
      @statistics.languages.each do |stat|
        next unless stat.percent_translated <= 0.0
        FileUtils.rm_r(stat.dirs)
        @zero_percent_dropped << stat.name
      end
      unless @zero_percent_dropped.empty?
        log_info "The following languages had translations files but they" \
          " amount to no useful strings so they were removed:" \
          " #{@zero_percent_dropped.join(', ')}"
      end

      if ENV.include?('RELEASEME_L10N_REQUIREMENT')
        # WARNING: before this could be supported as a general feature
        # this at the very least needs extension to establish how many strings
        # are meant to be there and then calculate the overall translated %.
        # A language that has 100% coverage with one single .po but is missing
        # 9 other .po files is not complete!
        # To fix this we could get() x-test or the templates (x-test likely
        # is easier because it behaves like a translation) and get stats of it.
        completion_requirement = ENV['RELEASEME_L10N_REQUIREMENT'].to_i
        @statistics.languages.each do |stat|
          percent = stat.percent_translated
          next if percent >= completion_requirement || zero_percent_dropped.include?(stat.name)
          FileUtils.rm_r(stat.dirs)
          log_warn "#{stat.name} wasn't sufficiently translated #{percent}!"
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
        CMakeEditor.append_po_install_instructions!(target) if edit_cmake

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
          CMakeEditor.append_optional_add_subdirectory!(target) if edit_cmake
        end

        # cmake_modules may be used by data assets, they are meant to be
        # folded into a join cmake_modules dir (doesn't make sense to me
        # why though, seems to me that does nothing but cause risk of clash)
        mod_target = "#{target}/cmake_modules".freeze
        Dir.glob("#{target}/*/cmake_modules").each do |mod|
          content = Dir.glob("#{mod}/*").reject { |x| x.include?('.svn') }
          FileUtils.mkpath(mod_target)
          FileUtils.cp_r(content, mod_target)
          FileUtils.rm_r(mod)
        end
      end

      # Process Qt translations. This MUST be after the PO translations as
      # we may wish to reuse the PO location if there's only Qt translations.
      if has_qt_translations
        final_target = qttarget # Can get modified.

        if edit_cmake
          # Update $srcdir/CMakeLists.txt
          CMakeEditor.append_poqm_install_instructions!(final_target)
        end
      end

      # Remove the empty translations directory
      FileUtils.rm_rf(target) unless has_po_translations
      FileUtils.rm_rf(qttarget) unless has_qt_translations
    end

    def verify_pot(potname)
      return unless potname.include?('$')
      raise "l10n pot appears to be a variable. cannot resolve #{potname}"
    end

    def po_file_dir(lang)
      "#{lang}/messages/#{@i18n_path}"
    end

    def get_messages(lang, tmpdir)
      vcs_path = po_file_dir(lang)

      @vcs.get(tmpdir, vcs_path)

      managed_types = %w[._desktop_ xml_mimetypes .appdata .metainfo ._json_]
      files = Dir.glob(File.join(tmpdir, '*')).collect do |file|
        name = File.basename(file)
        # desktop extraction: folded back into .deskto by scripty
        # https://bugs.kde.org/show_bug.cgi?id=424031
        next nil if managed_types.any? { |t| name.end_with?("#{t}.po") }

        # everything else is presumed a desirable artifact
        file
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
      else
        log_info "No translations for: #{missing.join(', ')}"
      end
    end
  end
end
