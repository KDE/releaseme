# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2007-2017 Harald Sitter <sitter@kde.org>

require 'fileutils'

require_relative 'cmakeeditor'
require_relative 'logable'
require_relative 'svn'
require_relative 'translationunit'

module ReleaseMe
  # Fetches documentation localization.
  class DocumentationL10n < TranslationUnit
    prepend Logable

    HANDBOOK_REGEX =
      'kdoctools_create_handbook\s*\(.+\s+SUBDIR\s+(?<item>[^\)\s]+)\s*\)'
      .freeze
    MANPAGE_REGEX =
      'kdoctools_create_manpage\s*\(\s*(?<item>man-[^\)\s]+\.docbook)'.freeze

    def vcs_l10n_path(lang)
      "#{lang}/docs/#{@i18n_path}/#{@project_name}"
    end

    def get(srcdir)
      @srcdir = File.expand_path(srcdir)
      @podir = podir_from(@srcdir)

      return if any_target_exists?(srcdir, "#{srcdir}/po", "#{srcdir}/poqm")

      langs_with_documentation = []
      langs_without_documentation = []

      log_info "Downloading documentations for #{srcdir}"

      # return false if doc_dirs.empty?
      unless translatables?
        log_warn <<-EOF
Could not find any documentation by checking for *.docbook files in the source.
Skipping documentation :(
        EOF
        return
      end

      queue = languages_queue(without: %w[en])
      each_language_with_tmpdir(queue) do |lang, tmpdir|
        if get_language(lang, tmpdir)
          langs_with_documentation << lang
        else
          langs_without_documentation << lang
        end
      end

      if !langs_with_documentation.empty?
        CMakeEditor.append_doc_install_instructions!(@podir)
      else
        log_warn 'There are no translations at all!'
      end

      return if langs_without_documentation.empty?
      log_info "No translations for: #{langs_without_documentation.join(', ')}"
    end

    private

    def podir_from(srcdir)
      if Dir.exist?("#{srcdir}/po")
        "#{srcdir}/po"
      elsif Dir.exist?("#{srcdir}/poqm")
        "#{srcdir}/poqm"
      else
        "#{srcdir}/po" # Default to po
      end
    end

    def docbook_dirs
      Dir.glob("#{@srcdir}/**/*.docbook").collect do |file|
        next nil if manpage?(file)
        name = File.basename(File.dirname(file))
        %w[doc docs docbook documentation].include?(name) ? nil : name
      end
    end

    def cmake_collect_matches(regex_str)
      Dir.glob("#{@srcdir}/**/CMakeLists.txt").collect do |file|
        next unless file.include?('doc/')
        regex = Regexp.new(regex_str, Regexp::IGNORECASE | Regexp::MULTILINE)
        (regex.match(File.read(file)) || {})[:item]
      end.compact
    end

    def kdoctools_dirs
      cmake_collect_matches(HANDBOOK_REGEX)
    end

    def manpages
      cmake_collect_matches(MANPAGE_REGEX)
    end

    def doc_dirs
      (docbook_dirs + kdoctools_dirs).uniq.compact
    end

    def translatables?
      !doc_dirs.empty? || !manpages.empty?
    end

    def manpage?(path)
      File.basename(path) =~ /man-.+\.docbook/
    end

    def find_all_docs(dir)
      doc_dirs.select { |doc_dir| Dir.exist?("#{dir}/#{doc_dir}") }
    end

    def find_all_manpages(dir)
      manpages.collect do |manpage|
        Dir.glob("#{dir}/**/#{manpage}").collect do |x|
          Pathname.new(x).relative_path_from(Pathname.new(dir)).to_s
        end
      end.flatten
    end

    def get_language(language, tmpdir)
      @vcs.get(tmpdir, "#{language}/docs/#{@i18n_path}")

      selection = (find_all_docs(tmpdir) + find_all_manpages(tmpdir)).uniq
      selection.each do |d|
        dest = "#{@podir}/#{language}/docs/#{File.dirname(d)}"
        FileUtils.mkpath(dest)
        FileUtils.cp_r("#{tmpdir}/#{d}", dest)
      end

      !selection.empty?
    end
  end
end
