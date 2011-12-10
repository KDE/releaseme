#!/usr/bin/env ruby

NAME      = "rekonq"
COMPONENT = "extragear"
SECTION   = "network"

$srcvcs   = "git"

def custom
    # Remove unnecessary stuff
    remover([
        "git_hooks","CTestConfig.cmake","scripts","commit-template"
    ])
end

$options = {:barrier=>75}

require File.join(File.dirname(__FILE__), 'lib/starter')
