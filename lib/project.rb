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

    # XML URL to use for resolution
    attr :xml_path, true

private
    attr :project_element, false
    attr :module_element, false
    attr :component_element, false

public
    # Creates a new Project. Identifier can be nil but must be set manually
    # before calling resolve.
    def initalize(project_identifier=nil)
        @id = project_identifier
        @identifier = nil
        @module = nil
        @component = nil
        @vcs = nil
        @xml_path = 'http://projects.kde.org/kde_projects.xml'
    end

    ##
    # call-seq:
    #  project.resolve() -> true or false
    #
    # Resolves identifier, module and component of the project at hand.
    def resolve!()
        return false if id.nil? or id.empty?

        xml_data = nil
        if @xml_path.start_with?("http:") or @xml_path.start_with?("https:")
            xml_data = Net::HTTP.get_response(URI.parse(@xml_path)).body
        else # Assumed to be local.
            xml_data = File.read(@xml_path)
        end
        doc = REXML::Document.new(xml_data)

        # Resolve project/module/component
        @project_element = nil
        projects = doc.root.get_elements('/kdeprojects/component/module/project')
        projects.each do | p |
            if p.attribute('identifier').to_s == id
                @project_element = p.dup
                @module_element = p.parent.dup
                @component_element = module_element.parent.dup
                break
            end
        end

        if @project_element.nil? or @module_element.nil? or @component_element.nil?
            return false;
        end

        @identifier = @project_element.attribute('identifier').to_s
        @module = @module_element.attribute('identifier').to_s
        @component = @component_element.attribute('identifier').to_s

        # Resolve git url.
        @vcs = nil
        urls = doc.root.get_elements("#{@project_element.xpath}/repo/url")
        urls.each do | url |
            if url.attribute('access').to_s == 'read-only' and
                url.attribute('protocol').to_s == 'git'
                @vcs = Git.new()
                @vcs.repository = url.text
            end
        end

        return true;
    end
end
