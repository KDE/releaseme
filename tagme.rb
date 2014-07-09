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
    opts.banner = "Usage: targe.rb [options]"

    opts.on("--version VERSION",
            "Version.",
            "   Versions should be kept in purely numerical format (good: x.x.x).",
            "   Alphanumerical version should be avoided if at all possible (bad: x.x.xbeta1).") do |v|
        options[:version] = v
    end
end.parse!

if options[:version].nil?
    puts "error, you need to set version"
    exit 1
end

# TODO: single project tag
# project_name = ARGV.pop
#
# p options
# p ARGV
# p project_name

#################

require_relative 'lib/project'
require_relative 'lib/source'

class TagProject
    attr :project, true
    attr :git_rev, true

end

def read_release_data()
    projects = Array.new
    File.open('release_data', 'r') do | file |
        file.each_line do | line |
            parts = line.split(';')
            next if parts.size < 3 # If we don't manage 3 parts the line is definitely crap.
            # 0 = project
            # 1 = branch
            # 2 = git rev
            project = TagProject.new
            project.project = Project.new(parts[0])
            while not project.project.resolve! do
                puts "Resolving the project #{parts[0]} failed. Going to try again in 5 seconds"
                sleep 5
            end
            project.project.vcs.branch = parts[1]
            project.git_rev = parts[2]
            projects << project
        end
    end
    return projects
end

tag_projects = read_release_data()
tag_projects.each do | tag_project |
    puts "--- #{tag_project.project.id} ---"
    source = Source.new
    source.target = "tmp-tagme"
    source.cleanup()
    source.get(tag_project.project.vcs, false)

    Dir.chdir(source.target) do
        puts "::git tag -s -m 'Tagging #{options[:version]}' v#{options[:version]} #{tag_project.git_rev}"
        %x[git tag -s -m 'Tagging #{options[:version]}' v#{options[:version]} #{tag_project.git_rev}]
        puts "::git push --tags origin"
        %x[git push --tags origin]
    end

    # TODO: impl l10n and docs and what have you
end
