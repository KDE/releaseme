#--
# Copyright (C) 2017 Harald Sitter <sitter@kde.org>
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

require_relative 'git'
require_relative 'projects_api'

module ReleaseMe
  # Opt-in api overlay replacing the XML projectsfile. Experimental
  module ProjectAPIOverlay
    # Class methods.
    module ClassMethods
      def from_data(api_project)
        # FIXME: not defined in remote QQ
        id = File.basename(api_project.path)

        # Resolve git url.
        vcs = Git.new
        vcs.repository = "git@git.kde.org:#{api_project.repo}"

        i18n_trunk = api_project.i18n.trunk_kf5
        i18n_stable = api_project.i18n.stable_kf5

        # Figure out which i18n path to use.
        i18n_path = api_project.i18n.component
        return false if !i18n_path || i18n_path.empty?

        # LTS branch only used for Plasma so unless it's set in a config file
        # just use stable branch
        i18n_lts = i18n_path == 'kde-workspace' ? plasma_lts : i18n_stable

        p Project.new(identifier: id,
                      vcs: vcs,
                      i18n_trunk: i18n_trunk,
                      i18n_stable: i18n_stable,
                      i18n_lts: i18n_lts,
                      i18n_path: i18n_path)
      end

      def from_xpath(id)
        # Try to list all projects within a prefix. Can be single match or
        # multiple if id is a component
        ProjectsAPI.list(id).collect do |path|
          from_data(ProjectsAPI.get(path))
        end
      rescue OpenURI::HTTPError
        # If the list comes back with an error try to find by id name.
        # This is for when the user wants to release 'kinfocenter'
        ProjectsAPI.find(id: id).collect do |path|
          from_data(ProjectsAPI.get(path))
        end
      end

      # @param url [String] find all Projects associated with this repo url.
      # @return [Array<Project>] can be empty
      def from_repo_url(url)
        # Git URIs are all over the place so much so that standard URI cannot
        # accurately parse them, so bypass URI entirely and do a super nasty split
        # run to get the path.
        without_scheme = url.split('//', 2)[-1]
        repo = without_scheme.split('/', 2)[-1]
        repo = repo.gsub(/\.git$/, '')
        api_project = ProjectsAPI.get_by_repo(repo)
        from_data(api_project)
      end
    end

    def self.prepended(base)
      class << base
        prepend ClassMethods
      end
    end
  end
end
