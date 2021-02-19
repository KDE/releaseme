# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017-2019 Harald Sitter <sitter@kde.org>

module ReleaseMe
  # https://techbase.kde.org/Localization/Concepts/Transcript
  # Downloads scripted l10n helpers.
  class L10nScriptDownloader
    attr_reader :artifacts

    attr_reader :lang
    attr_reader :tmpdir

    def initialize(lang, tmpdir, l10n)
      @lang = lang
      @tmpdir = tmpdir
      @scripts_dir = "#{tmpdir}/scripts"
      @l10n = l10n
      @artifacts = []
    end

    def download
      @l10n.vcs.get(@scripts_dir, script_file_dir, clean: true)
      return [] if Dir.glob("#{@scripts_dir}/**/**").none? { |f| File.file?(f) }

      @artifacts = [@scripts_dir]
    end

    private

    def script_file_dir
      "#{lang}/scripts/#{@l10n.i18n_path}"
    end
  end
end
