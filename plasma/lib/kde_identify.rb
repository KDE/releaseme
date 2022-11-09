#!/usr/bin/ruby

require 'httparty'

class KDEIndentify
  # Uses KDE's projects.kde.org API to get the path to the repo in invent.kde.org
  def self.get_kde_category(project)
    response = HTTParty.get("https://projects.kde.org/api/v1/identifier/#{project}")
    identifier_json = JSON.parse(response.body)
    path = identifier_json['path']
    result = path.split('/')
    result[0]
  end
end

if $PROGRAM_NAME == __FILE__
    if ARGV.length != 1
        puts "Usage: ./kde_identify.rb <repo>"
        exit
    end
    puts KDEIndentify.get_kde_category(ARGV[0])
end
