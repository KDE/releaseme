LANG=en_GB.UTF-8
LANGUAGE=en
LC_ALL=en_GB.UTF-8

VERSION=5.17.3
SHORT_VERSION=5.17
OLD_VERSION=5.17.2
ORIGIN=stable  # git branch as set in projects.k.o, set to trunk or stable or lts
FTPSTABLE=stable  # set to unstable or stable
OLD_FTPSTABLE=stable  # set to unstable or stable of previous release
BRANCH=Plasma/5.17 # set to master or Plasma/5.x
MINOR_RELEASE_MONTH="October 2019" # for announcement, when was 5.x.0 released

RELEASETYPE=bugfix # for changelog, set to beta, feature or bugfix

INFOCHECKOUT="/home/jr/src/www/www/info"                   # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/info/
ANNOUNCECHECKOUT="/home/jr/src/www/www/announcements"      # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/announcements/
L10NSCRIPTSCHECKOUT="/home/jr/src/www/l10n-kf5/scripts"   # svn+ssh://svn@svn.kde.org/home/kde/trunk/l10n-kde4/scripts/
WWWCHECKOUT="/home/jr/src/www/www"                         # svn+ssh://svn@svn.kde.org/home/kde/trunk/www/sites/www/
UPLOADSERVER="ftpadmin@master.kde.org"
#UPLOADSERVER="weegie"

RELEASEDATE="Tuesday, 12 November 2019" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEMONTH="November" # usually `LC_ALL=C date "+%B" --date="next Tue"`
TIMESINCELASTRELEASE="a fortnight's" # in sentence 'This release adds TIMESINCELASTRELEASE worth of new'

SCRATCH_SERVER=embra:tmp/ # somewhere to scp QA and tag files to

YOUTUBEID="https://peertube.mastodon.host/videos/embed/5a315252-2790-42b4-8177-94680a1c78fc" # The video ID used in URL for youtube

# command from   git clone kde:jriddell/appstream-metainfo-release-update
APPSTREAM_UPDATER="/home/jr/src/appstream-metainfo-release-update/appstream-metainfo-release-update/appstream-metainfo-release-update"

GPG_KEY=0xEC94D18F7F05997E
RELEASE_DUDE="Jonathan Riddell"
