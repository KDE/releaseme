#!/usr/bin/env ruby
#
# Generates a release tarball
#
# Copyright © 2014 Thomas Fischer <fischer@unix-ag.uni-kl.de>
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

NAME      = "kbibtex"
COMPONENT = "extragear"
SECTION   = "office"

$srcvcs   = "git"

def custom
    # Change version
    src_dir
    file = File.new( "src/version.h", File::RDWR|File::CREAT|File::TRUNC, 0644 )
    file.puts "#ifndef VERSION_H"
    file.puts "#define VERSION_H"
    file.puts  "const char *versionNumber = \"#{@version}\";"
    file.puts "#endif // VERSION_H"
    file.close

    # Clean CMakeLists.txt files
    file = File.new( "src/parts/CMakeLists.txt", File::RDWR )
    str = file.read
    file.rewind
    file.truncate( 0 )
    # Add dependency for in-source version.h file
    str.sub!( /include_directories[(][ \n]+/, "include_directories(\n    ${CMAKE_SOURCE_DIR}/src\n    ");
    # Remove GITrevision script
    str.sub!( /# creates version.h using cmake script[ \n]+add_custom_target[(][ \n]+GITrevision[^)]+[)]/m, "")
    # Do not require generating a version.h file
    str.sub!( /# version.h is a generated file[ \n]+set_source_files_properties[(][^)]+version.h[^)]+[)]/m, "")
    # Remove dependency to GITrevision to build part
    str.sub!( /add_dependencies[ (\n]+kbibtexpart[ \n]+GITrevision[ )\n]+/m, "")
    # Depend on shipped version.h file (generated above) instead of the one build by GITrevision
    str.sub!( /\${CMAKE_CURRENT_BINARY_DIR}\/version.h/, "${CMAKE_SOURCE_DIR}/src/version.h")
    file << str
    file.close
    file = File.new( "src/program/CMakeLists.txt", File::RDWR )
    str = file.read
    file.rewind
    file.truncate( 0 )
    # Add dependency for in-source version.h file
    str.sub!( /include_directories[(][ \n]+/, "include_directories(\n    ${CMAKE_SOURCE_DIR}/src\n    ");
    # Remove GITrevision script
    str.sub!( /# creates version.h using cmake script[ \n]+add_custom_target[(][ \n]+GITrevision[^)]+[)]/m, "")
    # Do not require generating a version.h file
    str.sub!( /# version.h is a generated file[ \n]+set_source_files_properties[(][^)]+version.h[^)]+[)]/m, "")
    # Remove dependency to GITrevision to build program
    str.sub!( /add_dependencies[ (\n]+kbibtex[ \n]+GITrevision[ )\n]+/m, "")
    # Depend on shipped version.h file (generated above) instead of the one build by GITrevision
    str.sub!( /\${CMAKE_CURRENT_BINARY_DIR}\/version.h/, "${CMAKE_SOURCE_DIR}/src/version.h")
    file << str
    file.close
    file = File.new( "src/CMakeLists.txt", File::RDWR )
    str = file.read
    file.rewind
    file.truncate( 0 )
    # Remove src/test as a subdirectory
    str.sub!( /add_subdirectory[(][ \n]+test[ \n]+[)]/m, "")
    file << str
    file.close


    # Remove unnecessary stuff
    remover([
        "testset", ".gitignore", ".reviewboardrc", "create-apidox.sh", "create-git-release.sh", "create-release.sh", "download-po-files-from-websvn.sh", "format_source_files.sh", "Messages.sh", "src/getgit.cmake", "src/test"
    ])

    base_dir
end

# get things started
require_relative 'lib/starter'
