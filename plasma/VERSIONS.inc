LANG=en_US.UTF-8
LANGUAGE=en
LC_ALL=en_US.UTF-8

VERSION=5.7.3
SHORT_VERSION=5.7
OLD_VERSION=5.7.2
ORIGIN=stable  # git branch as set in projects.k.o, set to trunk or stable
FTPSTABLE=stable  # set to unstable or stable
OLD_FTPSTABLE=stable  # set to unstable or stable of previous release
BRANCH=Plasma/5.7 # set to master or Plasma/5.x
MINOR_RELEASE_MONTH=July # for announcement, when was 5.x.0 released

RELEASETYPE=bugfix # for changelog, set to beta, feature or bugfix

INFOCHECKOUT="/home/jr/src/www/info"
ANNOUNCECHECKOUT="/home/jr/src/www/announcements"
L10NSCRIPTSCHECKOUT="/home/jr/src/www/l10n-kde4/scripts"
WWWCHECKOUT="/home/jr/src/www/www"
UPLOADSERVER="ftpadmin@depot.kde.org"
#UPLOADSERVER="weegie"

RELEASEDATE="Tuesday, 2 August 2016" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEMONTH="August" # usually `LC_ALL=C date "+%B" --date="next Tue"`
TIMESINCELASTRELEASE="two weeks'" # in sentence 'This release adds TIMESINCELASTRELEASE worth of new'

GPG_KEY=0xa506e6d4dd4d5088
RELEASE_DUDE="Jonathan Riddell"
