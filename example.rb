#!/usr/bin/env ruby

# VARs!
# NAME controls the output tarball name
# COMPONENT & SECTION:
#   These are used to build i18n paths
#     https://websvn.kde.org/trunk/l10n-kde4/templates/messages/SECTION-COMPONENT/
#   should point to the directory where your translation pots live
NAME      = "your_project_name"
COMPONENT = "organization_component e.g. base"
SECTION   = "organization_section e.g. extragear"

$: << File.dirname( __FILE__)
$srcvcs   = "git"

def custom
    remover(%w())
    base_dir
end

# get things started
require 'lib/starter'
