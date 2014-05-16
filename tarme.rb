#!/usr/bin/env ruby
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

require 'optparse'

options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: tarme.rb [options] PROJECT_NAME"

    opts.on("--origin trunk|stable", [:trunk, :stable],
            "Origin.",
            "   Used to deduce release branch and localization branches.") do |v|
        options[:origin] = v
    end

    opts.on("--version VERSION",
            "Version.",
            "   Versions should be kept in purely numerical format (good: x.x.x).",
            "   Alphanumerical version should be avoided if at all possible (bad: x.x.xbeta1).") do |v|
        options[:version] = v
    end
end.parse!

if options[:origin].nil? or options[:version].nil? or ARGV.empty?
    puts "error, you need to set origin and version"
    exit 1
end

project_name = ARGV.pop

p options
p ARGV
p project_name

#################

require_relative 'lib/documentation'
require_relative 'lib/kdegitrelease'
require_relative 'lib/kdel10n'
require_relative 'lib/project'
require_relative 'lib/projectsfile'

# TODO: move this somewhere
def find_element_from_xpath(xpath, element_identifier = nil)
    elements = ProjectsFile.instance.xml_doc.root.get_elements(xpath)
    unless element_identifier.nil? or element_identifier.empty?
        elements.each do | element |
            if (element_identifier == element.attribute('identifier').to_s)
                return element
            end
        end
    else
        return elements
    end
    return nil
end

# TODO: move this somewhere
def flat_project_resolver(project_id)
    doc = ProjectsFile.instance.xml_doc

    release_projects = Array.new
    if project_id.include?('/')
        # Wildcard release -> resolve by hand
        parts = project_id.split('/')
        if (parts.size < 2)
            puts "When using a wildcard project expression you must define component and module like component/module."
            puts "Whether you append anything after the"
            exit 1
        end
        component_element = find_element_from_xpath('/kdeprojects/component', parts.shift)
        module_element = find_element_from_xpath("#{component_element.xpath}/module", parts.shift)
        project_elements = find_element_from_xpath("#{module_element.xpath}/project")
        project_elements.each do | project_element |
            p = Project.new(project_element.attribute('identifier').to_s)
            p.set_elements(component_element, module_element, project_element)
            p.resolve_attributes!
            release_projects << p
        end
    else
        # Project release -> resolve through REXML query to project level
        project_element = find_element_from_xpath('/kdeprojects/component/module/project', project_id)
        p = Project.new(project_element.attribute('identifier').to_s)
        p.resolve!
        release_projects << p
    end
    return release_projects
end

release_projects = flat_project_resolver(project_name)

release_data_file = File.open("release_data", "w")
release_projects.each do | project |
    project_name = project.id
    release = KdeGitRelease.new()
    release.vcs.repository = project.vcs.repository
    release.vcs.branch = project.i18n_trunk if options[:origin] == :trunk
    release.vcs.branch = project.i18n_stable if options[:origin] == :stable
    release.source.target = "#{project_name}-#{options[:version]}"
    release.get()

    # FIXME: why not pass project itself? Oo
    # FIXME: origin should be validated? technically optparse enforces proper values
    l10n = KdeL10n.new(options[:origin], project.component, project.module)
    l10n.get(release.source.target)

    # FIXME: when one copies the l10n .new and adjust the class name arguments will be crap but nothing ever notices... lack of checks anyone?
    doc = DocumentationL10n.new(options[:origin], project_name, project.component, project.module)
    doc.get(release.source.target)

    release.archive()

    # FIXME: technically we need to track SVN revs for l10n as well...........
    # FIXME FIXME FIXME FIXME: need version
    project = project.id
    branch = release.vcs.branch
    hash = release.vcs.hash
    tar = release.archive_.filename
    md5 = %x[md5sum #{tar}].split(' ')[0] unless tar.nil?
    release_data_file.write("#{project};#{branch};#{hash};#{tar};#{md5}\n")
end
