#!/usr/bin/env ruby
#
# Generates a release tarball from KDE SVN
#
# Copyright (C) 2009 Harald Sitter <harald@getamarok.com>
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
# along with this program.  If
# Remove unnecessary stuffnot, see <http://www.gnu.org/licenses/>.

NAME      = "choqok"
COMPONENT = "playground"
SECTION   = "network"
BASEPATH  = Dir.getwd()

require 'fileutils'
require 'lib/libbase.rb'
require 'lib/librelease.rb'
require 'lib/libl10n.rb'
require 'lib/libtag.rb'

def release()
    # Change version
    srcDir()
    Dir.chdir("src")
    file = File.new( "main.cpp", File::RDWR )
    str = file.read()
    file.rewind()
    file.truncate( 0 )
    str.sub!( /static const char version\[\] = \".*\"/, "static const char version\[\] = \"#{@version}\"" )
    file << str
    file.close()
    Dir.chdir("..") #choqok

    # Remove unnecessary stuff
    toberemoved = []
    for object in toberemoved
        FileUtils.rm_rf(object)
    end

    baseDir()
end

informationQuery()

# TODO: why is this done here?
@folder = "#{NAME}-#{@version}" #create folder instance var

fetchSource()

fetchTranslations()

# fetchDocumentation()

createTranslationStats()

createTag()

release()

createTar()

createCheckSums()
