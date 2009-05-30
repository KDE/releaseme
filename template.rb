#!/usr/bin/env ruby

NAME      = "applicationname"
COMPONENT = "extragear"
SECTION   = "utils"

def custom
    src_dir
    remover([
        "junk","morejunk",".hiddenjunk"
    ])
    base_dir
end

$options = {:barrier=>75}

require 'lib/starter'
