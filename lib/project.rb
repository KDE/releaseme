#--
# Copyright (C) 2014-2015 Harald Sitter <apachelogger@ubuntu.com>
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

require_relative 'git'
require_relative 'projectsfile'

class Project
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
            if e.name == "path"
                path = e.text
                raise "unknown path" unless path
                parts = path.split('/')
                parts.pop # ditch last part as that is our name
                p parts
                @i18n_path = parts.join("-")
            end
        end
        return false unless @i18n_path

        return true
    end

    # @return [Array<Project>] never empty, can be nil if resolution failed
    def self.from_xpath(project_id)
        release_projects = []

        # Project release -> resolve through REXML query to project level
        release_projects = from_xpath_and_subxpath('/kdeprojects/component/module/project', '/', project_id)
        return release_projects unless release_projects.empty?
        release_projects = from_xpath_and_subxpath('/kdeprojects/component/module', '/project', project_id)
        return release_projects unless release_projects.empty?
        release_projects = from_xpath_and_subxpath('/kdeprojects/component', '/module/project', project_id)
        return release_projects unless release_projects.empty?

        # FIXME: return nil but this is slightly
        return nil
    end


private
    def self.find_element_from_xpath(xpath, element_identifier = nil)
        return ProjectsFile.xml_doc.root.get_elements(xpath)
    end
        # TODO: if a project is not under component/module it cannot be resolved
        #       This ultimately should:
        #       try to find a node in component/module/project
        #        -> match the path attribute as primary identifier (this allows
        #           kde/workspace and kde/workspace/foo as valid ids)
        #        -> match against the node 'identifier' property second (this allows
        #           workspace and foo as valid ids)
        #       if none was found traverese upwards until a match was found. i.e.
        #        look in component/module and check for match as above, then in
        #        component and check for match. if none was found resolution failed
        #       if a match was found, try to resolve child nodes, this allows
        #        meta ids such as kde/workspace to resolve to multiple actual
        #        projects

    # FIXME: testing
    def self.element_matches_path?(element, path)
        element.elements.each do |e|
            if e.name == "path" && e.text == path
                return true
            end
        end
        return false
    end

    # FIXME: testing
    def self.from_xpath_and_subxpath(xpath, subxpath, project_id)
        # Make sure we construct a valid path by forcing the subxpath to start with
        # a slash.
        subxpath.prepend('/') unless subxpath.start_with?('/')

        release_projects = []
        find_element_from_xpath(xpath).each do |element|
            if element.attribute("identifier").to_s == project_id || element_matches_path?(element, project_id)
                element.each_element("/#{element.xpath}#{subxpath}") do |e|
                    p = Project.new(project_element: e)
                    # TODO: we should do something on parse fail but we can't because the tests use incomplete pseudo data
#                     raise "failed to resolve attributes of #{project_id}"unless
                    p.resolve_attributes!
                    release_projects << p
                end
                if release_projects.empty? # Had no nested projects.
                    p = Project.new(project_element: element)
#                     raise "failed to resolve attributes of #{project_id}" unless
                    p.resolve_attributes!
                    release_projects << p
                end
                break
            end
        end
        return release_projects
    end
end
