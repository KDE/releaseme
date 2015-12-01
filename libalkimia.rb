#!/usr/bin/env ruby

NAME      = "libalkimia"
COMPONENT = "extragear"
SECTION   = "office"

$: << File.dirname( __FILE__)
$srcvcs   = "git"

def custom
    remover([
             ".reviewboardrc",
    ])
    base_dir
end

# get things started
require 'lib/starter'