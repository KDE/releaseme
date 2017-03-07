#!/usr/bin/env ruby
#--
# Copyright (C) 2015 Harald Sitter <sitter@kde.org>
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

require 'erb'
require 'tmpdir'

require_relative 'lib/project'
require_relative 'lib/source'

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
  def parse(rev)
    ancestor = `git describe --abbrev=0 --tags`.strip
    lines = `git log #{ancestor}#{rev} --oneline --no-merges`
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
      project.project = Project.from_xpath(parts[0])[0]
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
    source = Source.new
    source.target = tmpdir
    source.cleanup
    source.get(project.project.vcs, false)
    Dir.chdir(tmpdir) do
      log = Log.new.parse(project.git_rev)
      html = LogHtmlFormatter.format(log)
      File.write(File.join(output_dir, "#{project.project.identifier}.html"),
                 html)
    end
  end
end
