#!/usr/bin/env ruby

NAME      = "polkit-kde-agent-1"
COMPONENT = "extragear"
SECTION   = "base"

$: << File.dirname( __FILE__)
$srcvcs   = "git"

def custom
#    src_dir
#    remover([
#        "junk","morejunk",".hiddenjunk"
#    ])
#    base_dir
end

$options = {:barrier=>75}

require 'lib/starter'
