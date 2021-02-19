#!/usr/bin/env ruby
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017 Aleix Pol Gonzalez <aleixpol@kde.org>
# SPDX-FileCopyrightText: 2017 Harald Sitter <sitter@kde.org>

require_relative 'lib/releaseme'
require 'ostruct'
require 'optparse'

options = OpenStruct.new
OptionParser.new do |opts|
  opts.banner = <<-EOF
Usage: fetchpo.rb [ARGS] SOURCE_DIR
  EOF

  opts.separator ''

  opts.on('--origin ORIGIN', ReleaseMe::Origin::ALL,
          "Origin (#{ReleaseMe::Origin::ALL.join(' | ')}).",
          '   Used to deduce release branch and localization branches.') do |v|
    options[:origin] = v
  end

  opts.on('--project NAME', 'Repository name in git.kde.org') do |v|
    options[:project] = v
  end

  opts.on('--output-dir PATH', 'Where to put po translations.') do |v|
    options[:output_dir] = v
  end

  opts.on('--output-poqm-dir PATH', 'Where to put _qt.po translations.') do |v|
    options[:output_poqm_dir] = v
  end
end.parse!

unless options.origin && options.project && options.output_dir &&
       options.output_poqm_dir && ARGV.count == 1
  abort 'error, you need to set origin, project, output-dir, output-poqm-dir'
end

source_dir = File.expand_path(ARGV.pop)

elements =
  ReleaseMe::Project.from_repo_url("https://invent.kde.org/#{options.project}")
unless elements.count == 1
  abort "Found #{elements.count} elements for #{options.project}"
end

[options.output_dir, options.output_poqm_dir].each do |dir|
  if File.exist?(dir)
    abort "#{dir} should be created by the script, please remove first"
  end
end

project_information = elements[0]

l10n = ReleaseMe::L10n.new(options.origin, options.project,
                           project_information.i18n_path)
l10n.get(source_dir, options.output_dir, options.output_poqm_dir,
         edit_cmake: false)
