#!/usr/bin/env ruby

require_relative 'plasma_version'
require 'git'

# check the tag has been pushed
class PlasmaTagTest
  attr_accessor :version
  attr_accessor :repos

  def initialize
    plasma_versions = PlasmaVersion.new
    @version = plasma_versions.version
  end

  def grab_git_repos
    file_contents = File.read('git-repositories-for-release')
    @repos = file_contents.split(' ')
  end

  def check_tags
    repos.each do |repo|
      found = false
      tag_refs = Git.ls_remote("git://anongit.kde.org/#{repo}")['tags']["v#{@version}"]
      found = true if tag_refs != nil
      puts "Not found #{repo}" if found == false
      exit 1 if found == false
    end
    puts 'All good!'
  end
end
