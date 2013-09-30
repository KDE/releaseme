#!/usr/bin/env ruby

NAME      = "kio-mtp"
COMPONENT = "playground"
SECTION   = "base"

$srcvcs   = "git"

$options = {:barrier=>75}

require File.join(File.dirname(__FILE__), 'lib/starter')
