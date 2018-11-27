LANG=C.UTF-8
LANGUAGE=en
LC_ALL=C.UTF-8

VERSION=5.14.4
SHORT_VERSION=5.14
OLD_VERSION=5.14.3
ORIGIN=stable  # git branch as set in projects.k.o, set to trunk or stable
FTPSTABLE=stable  # set to unstable or stable
OLD_FTPSTABLE=stable  # set to unstable or stable of previous release
BRANCH=Plasma/5.14 # set to master or Plasma/5.x
MINOR_RELEASE_MONTH=October # for announcement, when was 5.x.0 released

RELEASETYPE=Bugfix # for changelog, set to Beta, Feature or Bugfix

INFOCHECKOUT="/home/jr/src/www/www/info"                   # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/info/
ANNOUNCECHECKOUT="/home/jr/src/www/www/announcements"      # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/announcements/
L10NSCRIPTSCHECKOUT="/home/jr/src/www/l10n-kde4/scripts"   # svn+ssh://svn@svn.kde.org/home/kde/trunk/l10n-kde4/scripts/
WWWCHECKOUT="/home/jr/src/www/www"                         # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/
UPLOADSERVER="ftpadmin@racnoss.kde.org"
#UPLOADSERVER="weegie"
PLASMA_CLONES="/home/jr/src/kde/"                       # a directory containing khotkeys/neongit/khotkeys/ etc for each repo

RELEASEDATE="Tuesday, 27 November 2018" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEMONTH="November" # usually `LC_ALL=C date "+%B" --date="next Tue"`
TIMESINCELASTRELEASE="a week's" # in sentence 'This release adds a TIMESINCELASTRELEASE worth of new'

SCRATCH_SERVER=embra:tmp/ # somewhere to scp QA and tag files to

YOUTUBEID="C2kR1_n_d-g" # The video ID used in URL for youtube

GPG_KEY=0xEC94D18F7F05997E
RELEASE_DUDE="Jonathan Riddell"
