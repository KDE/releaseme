#!/usr/bin/env ruby
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2015 Harald Sitter <sitter@kde.org>

require 'erb'
require 'ostruct'
require 'optparse'
require 'tmpdir'

require_relative 'lib/releaseme/project'
require_relative 'lib/releaseme/source'

options = OpenStruct.new
OptionParser.new do |opts|
  opts.banner = 'Usage: logme.rb [options]'

  opts.separator 'Saving change log based on previous tag as html <ul> fragment in <project>.html'
  opts.separator ''

  opts.on('--ancestor TAG', 'Specify ancestor tag.',
          'logme.rb currently requires to be called before tagme.rb. ' \
          'To avoid getting an empty changelog in the other case,' \
          ' the ancestor tag can be specified with this parameter.') do |v|
    options[:ancestor] = v
  end
end.parse!

class LogHtmlFormatter
  class EntryHtmlFormatter
    def self.format(entry)
      # TODO: erb
      "<li>#{ERB::Util.html_escape(entry.subject)}</li>"
    end
  end

  def self.format(log)
    # TODO: erb
    data = []
    data << '<ul>'
    log.entries.each do |entry|
      data << EntryHtmlFormatter.format(entry)
    end
    data << '</ul>'
    data.join($/)
  end
end

class Log
  class Entry
    attr_reader :revision
    attr_reader :subject

    def initialize(str)
      @revision, _, @subject = str.partition(' ')
      fail 'Could not parse log entry' unless @revision
    end
  end

  attr_reader :entries

  # FIXME: shit name
  def parse(rev, options)
    if options[:ancestor].nil?
        ancestor = `git describe --abbrev=0 --tags`.strip
    else
        ancestor = options.ancestor
    end
    puts "using ancestor tag '#{ancestor}'"
    lines = `git log #{ancestor}..#{rev} --oneline --no-merges`
    lines = lines.split($/).collect(&:strip)
    @entries = []
    lines.each do |line|
      # TODO: Move filter into entry init?
      entry = Entry.new(line)
      next if entry.subject.downcase.include?('update version number')
      next if entry.subject.include?('SVN_SILENT')
      entries << entry
    end
    self
  end
end

class TagProject
  attr_accessor :project
  attr_accessor :git_rev
end

# FIXME: move to lib :@
def read_release_data
  projects = []
  File.open('release_data', 'r') do | file |
    file.each_line do | line |
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

output_dir = Dir.pwd
projects = read_release_data
projects.each do | project |
  # FIXME: lol project.project xD
  puts "--- #{project.project.identifier} ---"
  Dir.mktmpdir do |tmpdir|
    # FIXME: this really could do with some threading.
    source = ReleaseMe::Source.new
    source.target = tmpdir
    source.cleanup
    source.get(project.project.vcs, false)
    Dir.chdir(tmpdir) do
      log = Log.new.parse(project.git_rev, options)
      html = LogHtmlFormatter.format(log)
      File.write(File.join(output_dir, "#{project.project.identifier}.html"),
                 html)
    end
  end
end
