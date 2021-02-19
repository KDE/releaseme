#!/usr/bin/env ruby
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2014-2016 Harald Sitter <sitter@kde.org>

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: branchme.rb [options]'

  opts.on('--name BRANCHNAME',
          'Branch name.',
          '   Branch names usually are prefixed by a project name (e.g. Plasma/1.0)') do |v|
    options[:branch] = v
  end
end.parse!

if options[:branch].nil?
  puts 'error, you need to set branchname'
  exit 1
end

# FIXME: blackbox
# ALL OF THIS!

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
      project.project = Project.from_find(parts[0])[0]
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
  source = Source.new
  source.target = 'tmp-branchme'
  source.cleanup
  source.get(tag_project.project.vcs, false)

  Dir.chdir(source.target) do
    puts "::git branch #{options[:branch]} #{tag_project.git_rev}"
    `git branch #{options[:branch]} #{tag_project.git_rev}`
    puts "::git checkout #{options[:branch]}"
    `git checkout #{options[:branch]}`
    puts "::git push origin #{options[:branch]}"
    `git push origin #{options[:branch]}`
  end

  # TODO: impl l10n and docs and what have you
end
