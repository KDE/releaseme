LANG=C.UTF-8
LANGUAGE=en
LC_ALL=C.UTF-8

VERSION=5.15.2
SHORT_VERSION=5.15
OLD_VERSION=5.15.1
ORIGIN=stable  # git branch as set in projects.k.o, set to trunk or stable
FTPSTABLE=stable  # set to unstable or stable
OLD_FTPSTABLE=stable  # set to unstable or stable of previous release
BRANCH=Plasma/5.15 # set to master or Plasma/5.x
MINOR_RELEASE_MONTH=February # for announcement, when was 5.x.0 released

RELEASETYPE=Bugfix # for changelog, set to Beta, Feature or Bugfix

INFOCHECKOUT="/home/jr/src/www/www/info"                   # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/info/
ANNOUNCECHECKOUT="/home/jr/src/www/www/announcements"      # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/announcements/
L10NSCRIPTSCHECKOUT="/home/jr/src/www/l10n-kf5/scripts"   # svn+ssh://svn@svn.kde.org/home/kde/trunk/l10n-kf5/scripts/
WWWCHECKOUT="/home/jr/src/www/www"                         # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/
UPLOADSERVER="ftpadmin@racnoss.kde.org"
#UPLOADSERVER="weegie"
PLASMA_CLONES="/home/jr/src/kde/"                       # a directory containing khotkeys/neongit/khotkeys/ etc for each repo

RELEASEDATE="Tuesday, 26 February 2019" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEMONTH="February" # usually `LC_ALL=C date "+%B" --date="next Tue"`
TIMESINCELASTRELEASE="a month's" # in sentence 'This release adds a TIMESINCELASTRELEASE worth of new'

SCRATCH_SERVER=embra:tmp/ # somewhere to scp QA and tag files to

YOUTUBEID="C2kR1_n_d-g" # The video ID used in URL for youtube

GPG_KEY=0xEC94D18F7F05997E
RELEASE_DUDE="Jonathan Riddell"
