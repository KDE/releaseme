#!/usr/bin/env ruby
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2014-2021 Harald Sitter <sitter@kde.org>

require 'ostruct'
require 'optparse'

require_relative 'lib/releaseme'

puts '           !! Make sure to read the wiki :) !!'
puts '     https://community.kde.org/ReleasingSoftware'

options = OpenStruct.new
OptionParser.new do |opts|
  opts.banner = 'Usage: tarme.rb [options] PROJECT_NAME(S)'

  opts.separator ''
  opts.separator 'Automatic Project Definition via projects.kde.org:'

  opts.on('--origin ORIGIN', ReleaseMe::Origin::ALL,
          "Origin (#{ReleaseMe::Origin::ALL.join(' | ')}).",
          '   Used to deduce release branch and localization branches.') do |v|
    options[:origin] = v
  end

  opts.on('--version VERSION', 'Version.',
          '   Versions should be kept in numerical format (good: x.x.x).',
          '   Alphanumerical version should be avoided if at all possible' \
            ' (bad: x.x-beta1).') do |v|
    options[:version] = v
  end

  opts.on('--debug', 'Enable debug output.') do |v|
    ENV['RELEASEME_DEBUG'] = '1'
  end

  opts.separator ''
  opts.separator 'Manual Project Definition:'

  opts.on('--from-config', 'Get configuration from projects/ directory.') do |c|
    options[:from_config] = c
  end
end.parse!

if ARGV.empty?
  warn 'You need to define at least one PROJECT_NAME'
  exit 1
end

unless (options.origin || options.from_config) && options.version
  warn 'error, you need to set origin and version'
  warn 'alternatively you can use a configuration file and use the' \
         ' --from-config switch'
  exit 1
end

if options.version.count('.') < 2
  warn 'You need a version number with at least 2 dots'
  exit 1
end

release_projects = []
if options[:from_config].nil?
  # Flatten because finding returns an array!
  release_projects += ARGV.collect { |x| ReleaseMe::Project.from_find(x) }.flatten
  if release_projects.empty?
    warn "The project #{project_name} could not be resolved." \
           ' Please note that you need to provide a concret name or path.'
    exit 1
  end

  # FIXME: runtime deps are not checked first
  # e.g. svn, git, xz...
else
  release_projects += ARGV.collect { |x| ReleaseMe::Project.from_config(x) }
end

release_data_file = File.open('release_data', 'w')
releases = release_projects.collect do |project|
  release = ReleaseMe::Release.new(project, options[:origin], options[:version])

  # FIXME: ALL gets() need to have appropriate handling and must be able to
  #        throw exceptions or return false when something goes wrong
  #        possibly a general fork() function would be useful to a) control IO
  #        better b) check the retvalue c) throw exception accordingly
  release.get
  release.archive

  # FIXME: present release_data format assumes that everything is git, so we
  # cannot add svn data
  next nil if release.project.vcs.is_a?(ReleaseMe::Svn)

  # FIXME FIXME FIXME FIXME: need version
  project = release.project.identifier
  branch = release.project.vcs.branch
  hash = release.project.vcs.hash
  tar = release.archive_.filename
  sha256 = `sha256sum #{tar}`.split(' ')[0] unless tar.nil?
  release_data_file.write("#{project};#{branch};#{hash};#{tar};#{sha256}\n")
  release
end

# At the end dump help output for all created tarballs.
releases.compact.each(&:help)
