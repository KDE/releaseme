LANG=en_US.UTF-8
LANGUAGE=en
LC_ALL=en_US.UTF-8

VERSION=5.10.95
SHORT_VERSION=5.11
OLD_VERSION=5.10.5
ORIGIN=trunk  # git branch as set in projects.k.o, set to trunk or stable
FTPSTABLE=unstable  # set to unstable or stable
OLD_FTPSTABLE=stable  # set to unstable or stable of previous release
BRANCH=master # set to master or Plasma/5.x
MINOR_RELEASE_MONTH=September # for announcement, when was 5.x.0 released

RELEASETYPE=Beta # for changelog, set to Beta, Feature or Bugfix

INFOCHECKOUT="/home/jr/src/www/www/info"                   # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/info/
ANNOUNCECHECKOUT="/home/jr/src/www/www/announcements"      # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/announcements/
L10NSCRIPTSCHECKOUT="/home/jr/src/www/l10n-kde4/scripts"   # svn+ssh://svn@svn.kde.org/home/kde/trunk/l10n-kde4/scripts/
WWWCHECKOUT="/home/jr/src/www/www"                         # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/
UPLOADSERVER="ftpadmin@racnoss.kde.org"
#UPLOADSERVER="weegie"

RELEASEDATE="Thursday, 13 September 2017" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEMONTH="September" # usually `LC_ALL=C date "+%B" --date="next Tue"`
TIMESINCELASTRELEASE="a month's" # in sentence 'This release adds TIMESINCELASTRELEASE worth of new'

SCRATCH_SERVER=embra:tmp/ # somewhere to scp QA and tag files to

YOUTUBEID="VtdTC2Mh070" # The video ID used in URL for youtube

GPG_KEY=0xEC94D18F7F05997E
RELEASE_DUDE="Jonathan Riddell"
