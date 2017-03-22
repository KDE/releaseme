#!/usr/bin/env ruby
#--
# Copyright (C) 2017 Aleix Pol Gonzalez <aleixpol@kde.org>
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

require_relative 'lib/releaseme'
require 'ostruct'
require 'optparse'

options = OpenStruct.new
OptionParser.new do |opts|
  opts.banner = 'Usage: fetchpo.rb --origin ORIGIN SOURCE_DIR OUTPUT_PO_DIR'

  opts.separator ''

  opts.on('--origin ORIGIN', ReleaseMe::Origin::ALL,
          "Origin (#{ReleaseMe::Origin::ALL.join(' | ')}).",
          '   Used to deduce release branch and localization branches.') do |v|
    options[:origin] = v
  end

  opts.on('--project NAME', 'ProjectName.',
          '   Repository name in git.kde.org') do |v|
    options[:project] = v
  end
end.parse!

unless options.origin && options.project && ARGV.count==2
  warn 'error, you need to set an origin'
  exit 1
end

output_dir = File.expand_path(ARGV.pop)
source_dir = File.expand_path(ARGV.pop)

elements = ReleaseMe::Project.from_repo_url("git://anongit.kde.org/#{options.project}")
unless elements.count == 1
  warn "Found #{elements.count} elements for #{options.project}"
  exit 2
end

if File.exist?(output_dir)
  warn "#{output_dir} should be created by the script, please remove first"
  exit 3
end

# ./fetchpo.rb --origin stable --project kalgebra ~/devel/frameworks/kalgebra/ /tmp/foo/po

project_information = elements[0]

l10n = ReleaseMe::L10n.new(options.origin, options.project, project_information.i18n_path)
l10n.get(source_dir, output_dir, false)
