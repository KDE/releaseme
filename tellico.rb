#!/usr/bin/env ruby

NAME      = "tellico"
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
    str.sub!( /TELLICO_VERSION \".*\"/, "TELLICO_VERSION \"#{@version}\"" )
    file << str
    file.close

    # Remove unnecessary stuff
    remover([
        "debian"
    ])

    base_dir    
end

#$options = {:barrier=>75}

require 'lib/starter'
