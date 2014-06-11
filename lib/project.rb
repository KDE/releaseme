#--
# Copyright (C) 2014 Harald Sitter <apachelogger@ubuntu.com>
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
    # The identifier to be resolved
    attr :id, true
    # Project identifer found. nil if not resolved.
    attr :identifier, false
    # Project module found. nil if not resolved.
    attr :module, false
    # Project component found. nil if not resolved.
    attr :component, false
    # VCS to use for this project
    attr :vcs, false
    # Branch used for i18n trunk
    attr :i18n_trunk, false
    # Branch used for i18n stable
    attr :i18n_stable, false

private
    # XML element of the project (e.g. yakuake's).
    attr :project_element, false
    # XML element of the module (e.g. utils').
    attr :module_element, false
    # XML element of the componenet (e.g. extragear's).
    attr :component_element, false

public
    # Creates a new Project. Identifier can be nil but must be set manually
    # before calling resolve.
    def initialize(project_identifier=nil)
        @id = project_identifier
        @identifier = nil
        @module = nil
        @component = nil
        @vcs = nil
        @i18n_trunk = nil
        @i18n_stable = nil
    end

    ##
    # Sets the REXML elements. This is the one and only way to set the elemnts.
    # All elements must be valid.
    # This function must be called before resolve_attributes!
    #--
    # FIXME: needs tests
    #++
    def set_elements(component_element, module_element, project_element)
        @component_element = component_element
        @module_element = module_element
        @project_element = project_element
    end

    ##
    # call-seq:
    #  project.resolve() -> true or false
    #
    # Resolves attributes, project name, module, and component of the project at hand.
    def resolve!()
        return false if id.nil? or id.empty?

        doc = ProjectsFile.instance.xml_doc

        # Resolve project/module/component
        @project_element = nil
        projects = doc.root.get_elements('/kdeprojects/component/module/project')
        projects.each do | p |
            if p.attribute('identifier').to_s == id
                @project_element = p
                @module_element = p.parent
                @component_element = module_element.parent
                break
            end
        end
        return resolve_attributes!
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
        if @project_element.nil? or @module_element.nil? or @component_element.nil?
            return false;
        end

        # TODO: projects have an 'active' flag, if that is false we likely
        #        should print a warnign and ask whether we really should continue

        doc = ProjectsFile.instance.xml_doc

        @identifier = @project_element.attribute('identifier').to_s
        @module = @module_element.attribute('identifier').to_s
        @component = @component_element.attribute('identifier').to_s

        # Resolve git url.
        @vcs = nil
        urls = doc.root.get_elements("#{@project_element.xpath}/repo/url")
        urls.each do | url |
            # FIXME: we need a way to switch between RO and RW as
            # a) distros like to use it so they may not have RW access
            # b) we need RW access for tagme, so tagme needs a way to explicitly
            #    request the RW repo url rather than the RO one...
            if url.attribute('access').to_s == 'read+write' and
                url.attribute('protocol').to_s == 'git'
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
            if i18n == 'trunk'
                @i18n_trunk = text
            elsif i18n == 'stable'
                @i18n_stable = text
            end
        end


        if @vcs.nil?
            return false
        end

        return true;
    end
end
