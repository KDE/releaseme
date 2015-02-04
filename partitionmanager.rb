#!/usr/bin/env ruby

NAME      = "partitionmanager"
COMPONENT = "extragear"
SECTION   = "sysadmin"

$srcvcs   = "git"

def custom
end

#require_relative 'lib/starter'
require File.join(File.dirname(__FILE__), 'lib/starter')
