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
    discover = @repos.find_index('discover')
    @repos[discover] = 'plasma-discover'
  end

  def check_tags
    repos.each do |repo|
      system("git clone --depth 1 --branch master git://anongit.kde.org/#{repo}")
      Dir.chdir(repo) do
        found = false
        system('git fetch --tags')
        git = Git.open('.')
        git.tags.each do |tag|
          found = true if tag.name == "v#{@version}"
        end
        puts "Not found #{repo}" if found == false
        exit 1 if found == false
      end
    end
    puts 'All good!'
  end
end
