#!/usr/bin/env ruby

NAME      = "colord-kde"
COMPONENT = "playground"
SECTION   = "graphics"

$srcvcs   = "git"

$options = {:barrier=>75}

require File.join(File.dirname(__FILE__), 'lib/starter')
