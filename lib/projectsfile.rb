#--
# Copyright (C) 2014-2015 Harald Sitter <apachelogger@ubuntu.com>
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

require 'fileutils'
require 'net/http'
require 'rexml/document'

##
# KDE Projects XML data management class.
# This class provides a singleton allowing easy access to the data provided by
# a KDE-style XML projects data file.
module ProjectsFile
  # Resets all instance variables to deafault values
  def reset!
    @autoload = true
    @xml_path = 'https://projects.kde.org/kde_projects.xml'
    @xml_data = nil
    @xml_doc = nil
    @cache_dir = "#{Dir.home}/.cache/releaseme"
    @cache_file = "#{@cache_dir}/kde_projects.xml"
    @cache_file_etag = "#{@cache_dir}/kde_projects.etag"
  end

  # @private
  def self.extended(base)
    super(base)
    reset!
  end

  extend self

  ##
  # XML URL to use for resolution (defaults to http://projects.kde.org/kde_projects.xml).
  # Should not be changed unless you know what you are doing.
  attr_accessor :xml_path

  # Bool on whether or not xml_doc and xml_data should automatically call load!
  attr_accessor :autoload

  # FIXME: for documentation purposes we want to use attr, but we also want to
  #        override the attr reader to on-demand load, find a way to not show
  #        this in docs
  def xml_doc
    load! if @xml_doc.nil? && @autoload
    @xml_doc
  end

  def xml_data
    load! if @xml_data.nil? && @autoload
    @xml_data
  end

  ##
  # Loads the XML file at xml_path and creates a REXML::Document instance.
  def load!
    if @xml_path.start_with?('http:') || @xml_path.start_with?('https:')
      @xml_data = load_from_network
    else # Assumed to be local.
      @xml_data = File.read(@xml_path)
    end
    @xml_doc = REXML::Document.new(@xml_data)
  end

  private

  def http_get
    uri = URI(@xml_path)
    cache_etag = File.read(@cache_file_etag) if File.exist?(@cache_file_etag)

    request = Net::HTTP::Get.new(uri)
    request['If-None-Match'] = cache_etag if cache_etag
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  # FIXME: test for cache stuff needed
  def load_from_network
    response = http_get

    if response.is_a?(Net::HTTPSuccess)
      data = response.body
      FileUtils.mkpath(@cache_dir)
      File.write(@cache_file_etag, response['etag']) if response.key?('etag')
      File.write(@cache_file, data)
    else
      print("Couldn't fetch ", @xml_path, ", using ", @cache_file, "\n")
      data = File.read(@cache_file) if File.exist?(@cache_file)
    end
    data
  end
end
