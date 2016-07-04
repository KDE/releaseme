#--
# Copyright (C) 2014-2016 Harald Sitter <sitter@kde.org>
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
require 'rexml/document'
require 'yaml'

require_relative 'git'
require_relative 'projectsfile'

class Project
  @@configdir = "#{File.expand_path(File.dirname(File.dirname(__FILE__)))}/projects/"

    # Project identifer found. nil if not resolved.
    attr_reader :identifier
    # VCS to use for this project
    attr_reader :vcs
    # Branch used for i18n trunk
    attr_reader :i18n_trunk
    # Branch used for i18n stable
    attr_reader :i18n_stable
    # Path used for i18n.
    attr_reader :i18n_path

    # Creates a new Project. Identifier can be nil but must be set manually
    # before calling resolve.
    def initialize(project_element: nil,
                   identifier: nil,
                   vcs: nil,
                   i18n_trunk: nil,
                   i18n_stable: nil,
                   i18n_path: nil)
        unless project_element || (identifier && vcs && i18n_trunk && i18n_stable && i18n_path)
            raise "Project construction either needs to happen with a project_element or all other values being !nil"
        end
        @identifier = identifier
        @vcs = vcs
        @i18n_trunk = i18n_trunk
        @i18n_stable = i18n_stable
        @i18n_path = i18n_path
        @project_element = project_element
    end

    ##
    # call-seq:
    #  project.resolve_attributes!() -> true or false
    #
    # Resolve project attributes by hand. All three REXML elements must be set before
    # this function will do anything useful. Also see set_elements().
    #--
    # FIXME: needs tests
    #++
    def resolve_attributes!()
        # FIXME: maybe should raise?
        return false if @project_element.nil?

        # TODO: projects have an 'active' flag, if that is false we likely
        #        should print a warnign and ask whether we really should continue

        doc = ProjectsFile.xml_doc

        @identifier = @project_element.attribute('identifier').to_s

        # Resolve git url.
        @vcs = nil
        urls = doc.root.get_elements("#{@project_element.xpath}/repo/url")
        urls.each do | url |
            # FIXME: we need a way to switch between RO and RW as
            # a) distros like to use it so they may not have RW access
            # b) we need RW access for tagme, so tagme needs a way to explicitly
            #    request the RW repo url rather than the RO one...
            if url.attribute('access').to_s == 'read+write' and
                url.attribute('protocol').to_s == 'ssh'
                @vcs = Git.new()
                @vcs.repository = url.text
            end
        end

        branches = doc.root.get_elements("#{@project_element.xpath}/repo/branch")
        branches.each do | branch |
            i18n = branch.attribute('i18n').to_s
            text = branch.text
            next if i18n.nil? or i18n.empty?
            next if text.nil? or text.empty? or text == 'none'
            if i18n == 'trunk_kf5'
                @i18n_trunk = text
            elsif i18n == 'stable_kf5'
                @i18n_stable = text
            end
        end

        return false unless @vcs

        # FIXME: needs a test
        # Figure out which i18n path to use.
        @project_element.elements.each do |e|
          if e.name == 'path'
            path = e.text
            fail 'unknown path' unless path
            parts = path.split('/')
            warn parts
            if parts[0] == 'kde' && parts[1] != 'workspace'
              # Everything but kde/workspace is flattend without the kde part.
              # kde/workspace on the other hand is kde-workspace.
              # So, for everything but workspace, drop the kde part.
              parts.shift
            end
            parts.pop # ditch last part as that is our name
            parts.pop while parts.size > 2
            @i18n_path = parts.join('-')
          end
        end
        return false unless @i18n_path

        return true
    end

    # @return [Array<Project>] never empty, can be nil if resolution failed
    def self.from_xpath(project_id)
      release_projects = []

      # Cleanup project_id. Mustn't have trailing slashes or a
      # wildcard asterisk. All not supported and in fact screwing with the
      # parser.
      project_id = project_id.chomp('*') while project_id.end_with?('*')
      project_id = project_id.chomp('/') while project_id.end_with?('/')

      %w(project module component).each do |element_type|
        release_projects += find_suitable_projects("//#{element_type}[@identifier]", project_id)
      end

      # FIXME: return nil but this is slightly meh
      release_projects
    end

    # Constructs a Project instance from the definition placed in projects/project_name.yml
    # @param project_name name of the yml file to look for. This is not reflected
    #   in the actual Project.identifier, just like the original xpath when using
    #   from_xpath.
    # @return Project never empty, raises exceptions when something goes wrong
    # @raise RuntimeError on every occasion ever. Unless something goes wrong deep inside.
    def self.from_config(project_name)
      ymlfile = "#{@@configdir}/#{project_name}.yml"
      unless File.exist?(ymlfile)
        fail "Project file for #{project_name} not found [#{ymlfile}]."
      end

      data = YAML.load(File.read(ymlfile))
      data = data.inject({}) do |tmphsh, (key, value)|
        key = key.downcase.to_sym
        if key == :vcs
          fail 'Vcs configuration has no type key.' unless value.key?('type')
          begin
            vcs_type = value.delete('type')
            require_relative "#{vcs_type.downcase}"
            value = Object.const_get(vcs_type).from_hash(value)
          rescue LoadError, RuntimeError => e
            raise "Failed to resolve the Vcs values #{value} -->\n #{e}"
          end
        end
        tmphsh[key] = value
        next tmphsh
      end

      Project.new(data)
    end

    private

    def self.element_matches_path?(element, path)
        element.elements.each do |e|
            if e.name == "path" && (e.text == path || e.text.start_with?(path))
                return true
            end
        end
        return false
    end

    def self.find_suitable_projects(xpath, project_id)
        ret = []
        ProjectsFile.xml_doc.root.get_elements(xpath).each do |element|
            suitable = false
            if element.attribute("identifier").to_s == project_id || element_matches_path?(element, project_id)
                suitable = true
            end
            next unless suitable
            has_children = false
            # FIXME: do we really need to xpath recursive here?
            element.each_element("/#{element.xpath}/*[@identifier]") do |_|
              has_children = true
              break
            end
            next if has_children
            pr = Project.new(project_element: element)
            pr.resolve_attributes!
            ret << pr
        end
        return ret
    end

end
