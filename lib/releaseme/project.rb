#--
# Copyright (C) 2014-2020 Harald Sitter <sitter@kde.org>
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

require 'net/http'
require 'yaml'

require_relative 'git'
require_relative 'logable'
require_relative 'projects_api'

module ReleaseMe
  class Project
    prepend Logable

    @@configdir = "#{File.dirname(File.dirname(File.expand_path(__dir__)))}/projects/"

    # Project identifer found. nil if not resolved.
    attr_reader :identifier
    # VCS to use for this project
    attr_reader :vcs
    # Branch used for i18n trunk
    attr_reader :i18n_trunk
    # Branch used for i18n stable
    attr_reader :i18n_stable
    # Branch used for i18n lts (same as stable except for Plasma)
    attr_reader :i18n_lts
    # Path used for i18n.
    attr_reader :i18n_path

    # Creates a new Project. Nothing may be nil except for i18n_lts!
    def initialize(identifier:,
                   vcs:,
                   i18n_trunk:,
                   i18n_stable:,
                   i18n_path:,
                   i18n_lts: nil)
      @identifier = identifier
      @vcs = vcs
      @i18n_trunk = i18n_trunk
      @i18n_stable = i18n_stable
      @i18n_lts = i18n_lts
      @i18n_path = i18n_path
    end

    def from_data(api_project)
      # FIXME: not defined in remote QQ
      id = File.basename(api_project.path)

      # Resolve git url.
      vcs = Git.new
      vcs.repository = "git@invent.kde.org:#{api_project.repo}"
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
      i18n_lts = i18n_path == 'plasma' ? plasma_lts : i18n_stable

      Project.new(identifier: id,
                  vcs: vcs,
                  i18n_trunk: i18n_trunk,
                  i18n_stable: i18n_stable,
                  i18n_lts: i18n_lts,
                  i18n_path: i18n_path)
    end

    def plasma_lts
      self.class.plasma_lts
    end

    class << self
      def plasma_lts
        ymlfile = "#{@@configdir}/plasma.yml"
        unless File.exist?(ymlfile)
          raise "Project file for Plasma not found [#{ymlfile}]."
        end

        data = YAML.load_file(ymlfile)
        data['i18n_lts']
      end

      # Constructs a Project instance from the definition placed in
      # projects/project_name.yml
      # @param project_name name of the yml file to look for. This is not
      #   reflected in the actual Project.identifier
      # @return Project never empty, raises exceptions when something goes wrong
      # @raise RuntimeError on every occasion ever. Unless something goes wrong
      #        deep inside.
      def from_config(project_name)
        ymlfile = "#{@@configdir}/#{project_name}.yml"
        unless File.exist?(ymlfile)
          raise "Project file for #{project_name} not found [#{ymlfile}]."
        end

        data = YAML.load(File.read(ymlfile))
        data = data.inject({}) do |tmphsh, (key, value)|
          key = key.downcase.to_sym
          if key == :vcs
            raise 'Vcs configuration has no type key.' unless value.key?('type')
            begin
              vcs_type = value.delete('type')
              require_relative vcs_type.downcase.to_s
              value = ReleaseMe.const_get(vcs_type).from_hash(value)
            rescue LoadError, RuntimeError => e
              raise "Failed to resolve the Vcs values #{value} -->\n #{e}"
            end
          end
          tmphsh[key] = value
          next tmphsh
        end

        Project.new(**data)
      end

      def from_data(api_project)
        # FIXME: not defined in remote QQ
        id = File.basename(api_project.path)

        # Resolve git url.
        vcs = Git.new
        vcs.repository = "git@invent.kde.org:#{api_project.repo}"
        # FIXME: hack to get readonly. should be RO by default and
        # frontend scripts should opt-into RW by setting a property
        # on us
        if ENV.include?('RELEASEME_READONLY')
          vcs.repository = "https://invent.kde.org/#{api_project.repo}"
        end

        i18n_trunk = api_project.i18n.trunk_kf5
        i18n_stable = api_project.i18n.stable_kf5

        # Figure out which i18n path to use.
        i18n_path = api_project.i18n.component
        return false if !i18n_path || i18n_path.empty?

        # LTS branch only used for Plasma so unless it's set in a config file
        # just use stable branch
        i18n_lts = api_project.repo.include?('plasma') ? plasma_lts : i18n_stable

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

      # May be a path or a basename.
      def from_find(id)
        return from_path(id) if id.include?('/')

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

      def from_path(path)
        [from_data(ProjectsAPI.get(path))]
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
    end
  end
end
