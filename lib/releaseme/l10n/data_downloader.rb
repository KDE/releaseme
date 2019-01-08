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
      @tmpdir_assets = "#{tmpdir}/data" # tmpdir is per-language.
      @tmpdir_modules = "#{tmpdir}/cmake_modules"
      @l10n = l10n
      @artifacts = []
    end

    def download
      @l10n.vcs.get(target_path, remote_path, clean: true)
      files = Dir.glob("#{target_path}/*").select { |f| File.file?(f) }
      return [] if files.empty?
      @artifacts = [@tmpdir_assets]
      # Some languages may have a cmake_modules dir to aid with the cmake logic
      # in their data directories. Grab this as well.
      # NB: the L10n class has to move these into po/
      if @l10n.vcs.get(target_cmake_modules_path, remote_cmake_modules_path,
                       clean: true)
        @artifacts << @tmpdir_modules
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

    def target_cmake_modules_path
      @tmpdir_modules
    end

    def remote_cmake_modules_path
      "#{lang}/cmake_modules"
    end
  end
end
