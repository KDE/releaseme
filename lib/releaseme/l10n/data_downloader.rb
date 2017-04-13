#--
# Copyright (C) 2017 Harald Sitter <apachelogger@ubuntu.com>
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
  # https://techbase.kde.org/Localization/Concepts/Non_Text_Resources
  # Downloads localized data files.
  class L10nDataDownloader
    attr_reader :artifacts

    attr_reader :lang
    attr_reader :tmpdir

    def initialize(lang, tmpdir, l10n)
      # Note that data assets are not template dependent, so we have no
      # benefit from caching an ls over simply running the get when needed.
      # So we are not using a cache for this.
      @lang = lang
      @tmpdir = tmpdir
      @tmpdir_assets = "#{tmpdir}/#{@lang}/data"
      @l10n = l10n
      @artifacts = []
    end

    def download
      @l10n.vcs.get(target_path, remote_path)
      unless Dir.glob("#{target_path}/*").select { |f| File.file?(f) }.empty?
        @artifacts = [@tmpdir_assets]
      end
      @artifacts
    end

    private

    def project_name
      @l10n.project_name
    end

    def target_path
      "#{@tmpdir_assets}/#{File.basename(remote_path)}"
    end

    def remote_path
      "#{lang}/data/#{@l10n.i18n_path}/#{project_name}"
    end
  end
end
