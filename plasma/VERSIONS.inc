LANG=en_US.UTF-8
LANGUAGE=en
LC_ALL=en_US.UTF-8

VERSION=5.9.2
SHORT_VERSION=5.9
OLD_VERSION=5.9.1
ORIGIN=stable  # git branch as set in projects.k.o, set to trunk or stable
FTPSTABLE=stable  # set to unstable or stable
OLD_FTPSTABLE=stable  # set to unstable or stable of previous release
BRANCH=Plasma/5.9 # set to master or Plasma/5.x
MINOR_RELEASE_MONTH=January # for announcement, when was 5.x.0 released

RELEASETYPE=bugfix # for changelog, set to Beta, Feature or Bugfix

INFOCHECKOUT="/home/jr/src/www/www/info"                   # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/info/
ANNOUNCECHECKOUT="/home/jr/src/www/www/announcements"      # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/announcements/
L10NSCRIPTSCHECKOUT="/home/jr/src/www/l10n-kde4/scripts"   # svn+ssh://svn@svn.kde.org/home/kde/trunk/l10n-kde4/scripts/
WWWCHECKOUT="/home/jr/src/www/www"                         # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/
UPLOADSERVER="ftpadmin@depot.kde.org"
#UPLOADSERVER="weegie"

RELEASEDATE="Tuesday, 14 February 2017" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEMONTH="February" # usually `LC_ALL=C date "+%B" --date="next Tue"`
TIMESINCELASTRELEASE="two week's" # in sentence 'This release adds TIMESINCELASTRELEASE worth of new'

GPG_KEY=0xEC94D18F7F05997E
RELEASE_DUDE="Jonathan Riddell"
