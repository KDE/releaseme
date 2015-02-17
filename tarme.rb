#!/usr/bin/env ruby
#--
# Copyright (C) 2014-2015 Harald Sitter <sitter@kde.org>
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

require 'ostruct'
require 'optparse'

require_relative 'lib/requirements'

require_relative 'lib/documentation'
require_relative 'lib/release'
require_relative 'lib/l10n'
require_relative 'lib/project'
require_relative 'lib/projectsfile'

options = OpenStruct.new
OptionParser.new do |opts|
  opts.banner = 'Usage: tarme.rb [options] PROJECT_NAME'

  opts.separator ''
  opts.separator 'Automatic Project Definition via projects.kde.org:'

  opts.on('--origin ORIGIN', [:trunk, :stable], 'Origin (trunk or stable).',
          '   Used to deduce release branch and localization branches.') do |v|
    options[:origin] = v
  end

  opts.on('--version VERSION', 'Version.',
          '   Versions should be kept in numerical format (good: x.x.x).',
          '   Alphanumerical version should be avoided if at all possible' \
            ' (bad: x.x-beta1).') do |v|
    options[:version] = v
  end

  opts.separator ''
  opts.separator 'Manual Project Definition:'

  opts.on('--from-config', 'Get configuration from projects/ directory.') do |c|
    options[:from_config] = c
  end
end.parse!

if ARGV.empty?
  warn 'You need to define a PROJECT_NAME'
  exit 1
end

unless (options.origin || options.from_config) && options.version
  warn 'error, you need to set origin and version'
  warn 'alternatively you can use a configuration file and use the' \
         ' --from-config switch'
  exit 1
end

project_name = ARGV.pop

release_projects = []
if options[:from_config].nil?
  release_projects = Project.from_xpath(project_name)
  if release_projects.empty?
    warn 'The project #{project_name} could not be resolved.' \
           ' Please note that you need to provide a concret name or path.'
    exit 1
  end

  # FIXME: runtime deps are not checked first
  # e.g. svn, git, xz...
else
  release_projects << Project.from_config(project_name)
end

release_data_file = File.open('release_data', 'w')
release_projects.each do | project |
  project_name = project.identifier
  release = Release.new(project, options[:origin], options[:version])

  # FIXME: ALL gets() need to have appropriate handling and must be able to
  #        throw exceptions or return false when something goes wrong
  #        possibly a general fork() function would be useful to a) control IO
  #        better b) check the retvalue c) throw exception accordingly
  release.get
  release.archive

  # FIXME: technically we need to track SVN revs for l10n as well...........
  # FIXME FIXME FIXME FIXME: need version
  project = release.project.identifier
  branch = release.project.vcs.branch
  hash = release.project.vcs.hash
  tar = release.archive_.filename
  sha256 = `sha256sum #{tar}`.split(' ')[0] unless tar.nil?
  release_data_file.write("#{project};#{branch};#{hash};#{tar};#{sha256}\n")
end
