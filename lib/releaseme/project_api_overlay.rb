#--
# Copyright (C) 2017-2020 Harald Sitter <sitter@kde.org>
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
require_relative 'logable'
require_relative 'projects_api'

module ReleaseMe
  # Opt-in api overlay replacing the XML projectsfile. Experimental
  module ProjectAPIOverlay
    # Class methods.
    module ClassMethods
      prepend Logable

      def from_data(api_project)
        # FIXME: not defined in remote QQ
        id = File.basename(api_project.path)

        # Resolve git url.
        vcs = invent_or_git_vcs(api_project.repo)
        # FIXME: hack to get readonly. should be RO by default and
        # frontend scripts should opt-into RW by setting a property
        # on us
        if ENV.include?('RELEASEME_READONLY')
          vcs.repository = "https://anongit.kde.org/#{api_project.repo}"
        end

        i18n_trunk = api_project.i18n.trunk_kf5
        i18n_stable = api_project.i18n.stable_kf5

        # Figure out which i18n path to use.
        i18n_path = api_project.i18n.component
        return false if !i18n_path || i18n_path.empty?

        # LTS branch only used for Plasma so unless it's set in a config file
        # just use stable branch
        i18n_lts = i18n_path == 'kde-workspace' ? plasma_lts : i18n_stable

        Project.new(identifier: id,
                    vcs: vcs,
                    i18n_trunk: i18n_trunk,
                    i18n_stable: i18n_stable,
                    i18n_lts: i18n_lts,
                    i18n_path: i18n_path)
      end

      def from_xpath(id)
        # By default assume id is the name of a project and nothing else.
        # This means we'll get the project if there is a module AND a project
        # of the same name. More importantly this means listing recursively
        # is no longer a thing so releasing a "module" as a use case is not
        # supported. Also ids then need to be unique and from_find asserts that.
        # https://bugs.kde.org/show_bug.cgi?id=420501
        warn 'from_xpath is deprecated; use from_find instead'
        from_find(id)
      end

      def from_find(id)
        ret = ProjectsAPI.find(id: id).collect do |path|
          from_data(ProjectsAPI.get(path))
        end
        # Ensure project names are in fact unique.
        raise "Unexpectedly found multiple matches for #{id}" if ret.size > 1
        ret
      rescue OpenURI::HTTPError => e
        return [] if e.io.status[0] == '404' # [0] is code, [1] msg
        raise e
      end

      # @param url [String] find all Projects associated with this repo url.
      # @return [Array<Project>] can be empty
      def from_repo_url(url)
        # Git URIs are all over the place so much so that standard URI cannot
        # accurately parse them, so bypass URI entirely and do a super nasty
        # split run to get the path.
        without_scheme = url.split('//', 2)[-1]
        repo = without_scheme.split('/', 2)[-1]
        repo = repo.gsub(/\.git$/, '')
        api_project = ProjectsAPI.get_by_repo(repo)
        [from_data(api_project)]
      rescue OpenURI::HTTPError => e
        return [] if e.io.status[0] == '404' # Not a thing
        raise e # Otherwise raise, the error was unexpected on an API level.
      end

      private

      def invent_or_git_vcs(repo)
        # Repos that have migrated to invent will respond to ls-remote,
        # repos that have not will not. See if the writable invent repo exists
        # if not, drop to git.kde.org. If the user doesn't have push access
        # to invent that will also trip up this check and they'll default
        # to git.kde.org. This is a bit unfortunate :|
        vcs = Git.new
        vcs.repository = "git@invent.kde.org:kde/#{repo}"
        return vcs if vcs.exist?
        log_info 'Repo not writable on invent.kde.org. Defaulting to git.kde.org'
        vcs = Git.new
        vcs.repository = "git@git.kde.org:#{repo}"
        vcs
      end
    end

    def self.prepended(base)
      class << base
        prepend ClassMethods
      end
    end
  end
end
