#!/usr/bin/env ruby

NAME      = "skrooge"
COMPONENT = "extragear"
SECTION   = "office"

$srcvcs   = "git"

def custom
    # Change version
    src_dir
    file = File.new( "CMakeLists.txt", File::RDWR )
    str = file.read
    file.rewind
    file.truncate( 0 )
    str.sub!( /SKG_VERSION \".*\"/, "SKG_VERSION \"#{@version}\"" )
    file << str
    file.close

    # Remove unnecessary stuff
    remover([
        "20101101-presentation skrooge.odp","20110319-KDE4.6 release party-skrooge.odp"
    ])

    base_dir    
end

#$options = {:barrier=>75}

require 'lib/starter'
