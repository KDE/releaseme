#!/usr/bin/env ruby

NAME      = "kplayer"
COMPONENT = "extragear"
SECTION   = "multimedia"

$srcvcs   = "git"

def custom
end

#require_relative 'lib/starter'
require File.join(File.dirname(__FILE__), 'lib/starter')
