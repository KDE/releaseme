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

#################

require_relative 'lib/documentation'
require_relative 'lib/release'
require_relative 'lib/kdel10n'
require_relative 'lib/project'
require_relative 'lib/projectsfile'

release_projects = Project::from_xpath(project_name)

# FIXME: runtime deps are not checked first
# e.g. svn, git, xz...

release_data_file = File.open("release_data", "w")
release_projects.each do | project |
    project_name = project.identifier
    release = Release.new(project.vcs.clone)
    release.vcs.branch = project.i18n_trunk if options[:origin] == :trunk
    release.vcs.branch = project.i18n_stable if options[:origin] == :stable
    release.source.target = "#{project_name}-#{options[:version]}"

    # FIXME: ALL gets() need to have appropriate handling and must be able to
    #        throw exceptions or return false when something goes wrong
    #        possibly a general fork() function would be useful to a) control IO
    #        better b) check the retvalue c) throw exception accordingly
    release.get()

    # FIXME: why not pass project itself? Oo
    # FIXME: origin should be validated? technically optparse enforces proper values
    l10n = KdeL10n.new(options[:origin], project.i18n_path)
    l10n.get(release.source.target)

    # FIXME: when one copies the l10n .new and adjust the class name arguments will be crap but nothing ever notices... lack of checks anyone?
    doc = DocumentationL10n.new(options[:origin], project_name, project.i18n_path)
    doc.get(release.source.target)

    release.archive()

    # FIXME: technically we need to track SVN revs for l10n as well...........
    # FIXME FIXME FIXME FIXME: need version
    project = project.identifier
    branch = release.vcs.branch
    hash = release.vcs.hash
    tar = release.archive_.filename
    sha256 = %x[sha256sum #{tar}].split(' ')[0] unless tar.nil?
    release_data_file.write("#{project};#{branch};#{hash};#{tar};#{sha256}\n")
end
