#!/usr/bin/env ruby

NAME      = "kmymoney"
COMPONENT = "extragear"
SECTION   = "office"

$: << File.dirname( __FILE__)
$srcvcs   = "git"

def custom
    # Fix the CMakeLists as translated documentation is included in
    # releases

    file = File.new( "CMakeLists.txt", File::RDWR )
    str = file.read
    file.rewind
    file.truncate( 0 )
    str.sub!( /add_subdirectory\( doc \)/, "" )
    file << str
    file.close
end

require 'lib/starter'
