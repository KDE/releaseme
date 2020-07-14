#--
# Copyright (C) 2017-2019 Harald Sitter <sitter@kde.org>
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

    def templates
      @l10n.templates
    end

    def script_file_dir
      "#{lang}/scripts/#{@l10n.i18n_path}"
    end
  end
end
