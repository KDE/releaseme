#!/usr/bin/env ruby

require_relative 'plasma_version'
require 'git'

class PlasmaTagTest
    attr_accessor :version
    attr_accessor :repos

    def initialize()
      plasma_versions = PlasmaVersion.new
      @version = plasma_versions.version
      Dir.chdir(plasma_versions.plasma_clones)
      @version = "5.11.0"
    end

    def get_git_repos()
      fileContents = File.read('/home/jr/src/releaseme/releaseme/plasma/git-repositories-for-release')
      @repos = fileContents.split(' ')
      discover = @repos.find_index('discover')
      @repos[discover] = 'plasma-discover'
    end

    def check_tags
      repos.each do |repo|
        Dir.chdir(repo + '/kdegit/' + repo) do
          found = false
          system('git fetch --tags')
          git = Git.open('.')
          git.tags.each do |tag|
            if tag.name == "v#{@version}"
              found = true
            end
          end
          puts "Not found #{repo}" if found == false
          exit 0 if found == false
        end
      end
      puts "All good!"
    end
end

#class with methods to:
# get list of git repos
# for each repo git tag
# check it has tag for version
# print result
