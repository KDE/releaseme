#!/usr/bin/env ruby
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2014-2016 Harald Sitter <sitter@kde.org>

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: tagme.rb [options]'

  opts.on('--version VERSION',
          'Version.',
          '   Versions should be kept in purely numerical format (good: x.x.x).',
          '   Alphanumerical version should be avoided if at all possible (bad: x.x.xbeta1).') do |v|
    options[:version] = v
  end
end.parse!

if options[:version].nil?
  puts 'error, you need to set version'
  exit 1
end

# TODO: single project tag
# project_name = ARGV.pop
#
# p options
# p ARGV
# p project_name

#################

require_relative 'lib/releaseme'

class TagProject
  attr_accessor :project
  attr_accessor :git_rev
end

# FIXME: move to lib :@
def read_release_data
  projects = []
  File.open('release_data', 'r') do |file|
    file.each_line do |line|
      parts = line.split(';')
      next if parts.size < 3 # If we don't manage 3 parts the line is definitely crap.
      # 0 = project
      # 1 = branch
      # 2 = git rev
      project = TagProject.new
      project.project = ReleaseMe::Project.from_find(parts[0])[0]
      project.project.vcs.branch = parts[1]
      project.git_rev = parts[2]
      projects << project
    end
  end
  projects
end

tag_projects = read_release_data
tag_project_names = tag_projects.collect { |x| x.project.identifier }
if tag_project_names.include?(nil)
  raise 'Failed to resolve one or more releae_data entries'
end
dupes = tag_project_names.group_by { |x| x }
                         .select { |_, v| v.size > 1 }
                         .map(&:first)
unless dupes.empty?
  raise 'The following entities appear more than once in the release data!' \
        ' This should absolutely not happen and indicates that your data is' \
        ' broken. Best start from scratch or manually repair the data to only' \
        " contain each entity once.\nDuplicates:\n#{dupes.join(', ')}"
end
tag_projects.each do |tag_project|
  puts "--- #{tag_project.project.identifier} ---"
  source = ReleaseMe::Source.new
  source.target = 'tmp-tagme'
  source.cleanup
  source.get(tag_project.project.vcs, false)

  Dir.chdir(source.target) do
    puts "::git tag -s -m 'Tagging #{options[:version]}' v#{options[:version]} #{tag_project.git_rev}"
    `git tag -s -m 'Tagging #{options[:version]}' v#{options[:version]} #{tag_project.git_rev}`
    puts "::git push origin v#{options[:version]}"
    `git push origin v#{options[:version]}`
  end

end
