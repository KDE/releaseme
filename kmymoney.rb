#!/usr/bin/env ruby

NAME      = "kmymoney"
COMPONENT = "extragear"
SECTION   = "office"

$: << File.dirname( __FILE__)
$srcvcs   = "git"

def custom
end

require 'lib/starter'
