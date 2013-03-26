#!/usr/bin/env ruby
#
# Generates a release tarball of KPhotoAlbum
#
# Copyright © 2012 Miika Turkia <miika.turkia@gmail.com>
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

NAME      = "kphotoalbum"
COMPONENT = "extragear"
SECTION   = "graphics"

$: << File.dirname( __FILE__)
$srcvcs   = "git"

def custom
    # Change version
    src_dir
    file = File.new( "version.h.in", File::RDWR )
    str = file.read
    file.close
    file = File.new( "version.h", File::RDWR|File::CREAT|File::TRUNC, 0644 )
    str.sub!( /"@KPA_VERSION@"/, "\"#{@version}\"" )
    file << str
    file.close

    # Fix the CMakeLists as translated documentation is included in
    # releases

    file = File.new( "CMakeLists.txt", File::RDWR )
    str = file.read
    file.rewind
    file.truncate( 0 )
    str.sub!( /add_subdirectory\( doc \)/, "" )
    file << str
    file.close


    # A hack to make sure a couple of possibly missing entities used in
    # our translated documentation don't break the compilation on some
    # older systems

    file = File.new( "doc/nl/index.docbook", File::RDWR )
    str = file.read
    file.rewind
    file.truncate( 0 )
    str.sub!( /\]>/, "  <!ENTITY ged.vertaald           '<othercredit role=\"translator\"><firstname>Dit document is nog maar gedeeltelijk vertaald.</firstname> <surname>Wilt u meehelpen, stuur een bericht naar:</surname><affiliation><address> <email>kde-i18n-nl@kde.org</email></address></affiliation> <contrib>Nieuwe vertaler</contrib></othercredit>'>\n]>" )
    file << str
    file.close

    file = File.new( "doc/fr/index.docbook", File::RDWR )
    str = file.read
    file.rewind
    file.truncate( 0 )
    str.sub!( /\]>/, "  <!ENTITY traducteurXavierBesnard       '<othercredit role=\"translator\"><firstname>Xavier</firstname><surname>Besnard</surname><affiliation><address><email>ktranslator31@yahoo.fr</email></address></affiliation><contrib>Traduction française&nbsp;</contrib></othercredit>'>\n]>" )
    file << str
    file.close

    # end hack
end

$options = {:barrier=>75}

require 'lib/starter'
