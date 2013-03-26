#!/usr/bin/env ruby

NAME      = "skrooge"
COMPONENT = "extragear"
SECTION   = "office"

$: << File.dirname( __FILE__)
$srcvcs   = "git"

def custom
    # Change version
    src_dir
    file = File.new( "CMakeLists.txt", File::RDWR )
    str = file.read
    file.rewind
    file.truncate( 0 )
    str.sub!( /SKG_VERSION \".*\"/, "SKG_VERSION \"#{@version}\"" )
    str.sub!( /Build the test\" ON/, "Build the test\" OFF" )
    file << str
    file.close

    # Remove unnecessary stuff
    remover([
        "examples",
        "tests",
        "templates"
    ])

    base_dir    
end

$options = {:barrier=>75}

require 'lib/starter'
