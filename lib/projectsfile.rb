#--
# Copyright (C) 2014 Harald Sitter <apachelogger@ubuntu.com>
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

require 'net/http'
require 'rexml/document'
require 'singleton'

##
# KDE Projects XML data management class.
# This class provides a singleton allowing easy access to the data provided by
# a KDE-style XML projects data file.
class ProjectsFile
    include Singleton

    ##
    # XML URL to use for resolution (defaults to http://projects.kde.org/kde_projects.xml).
    # Should not be changed unless you know what you are doing.
    attr :xml_path, false

    # Retrieved XML data.
    attr :xml_data, false

    # XML REXML::Document.
    attr :xml_doc, false

    # FIXME: for documentation purposes we want to use attr, but we also want to
    #        override the attr reader to on-demand load, find a way to not show this in docs
    def xml_doc()
        load! if @xml_doc.nil?
        return @xml_doc
    end

    def xml_data()
        load! if @xml_data.nil?
        return @xml_data
    end

    ##
    # Loads the XML file at xml_path and creates a REXML::Document instance.
    def load!()
        if @xml_path.start_with?("http:") or @xml_path.start_with?("https:")
            @xml_data = Net::HTTP.get_response(URI.parse(@xml_path)).body
        else # Assumed to be local.
            @xml_data = File.read(@xml_path)
        end
        @xml_doc = REXML::Document.new(@xml_data)
    end

private
    def initialize()
        @xml_path = 'http://projects.kde.org/kde_projects.xml'
        @xml_data = nil
        @xml_doc = nil
    end
end