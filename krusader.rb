#!/usr/bin/env ruby

NAME      = "krusader"
COMPONENT = "extragear"
SECTION   = "utils"

$srcvcs   = "git"

def custom
end

#require_relative 'lib/starter'
require File.join(File.dirname(__FILE__), 'lib/starter')
