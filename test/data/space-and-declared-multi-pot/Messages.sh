#! /bin/sh
potfile=kexi
other_pot=amarokcollectionscanner_qt.pot
kexi_xgettext amarok.pot $LIST
kexi_xgettext $other_pot
