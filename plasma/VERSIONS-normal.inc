VERSION=5.19.90
SHORT_VERSION=5.20
OLD_VERSION=5.19.5
ORIGIN=trunk  # git branch as set in projects.k.o, set to trunk or stable or lts
FTPSTABLE=unstable  # set to unstable or stable
OLD_FTPSTABLE=stable  # set to unstable or stable of previous release
BRANCH=master # set to master or Plasma/5.x
MINOR_RELEASE_MONTH="September 2020" # for announcement, when was 5.x.0 released

RELEASETYPE=beta # for changelog, set to beta, feature or bugfix

INFOCHECKOUT="/home/bshah/src/Websites/kde-org/info"                   # git@invent.kde.org:websites/kde-org.git
ANNOUNCECHECKOUT="/home/bshah/src/Websites/kde-org/announcements"  # git@invent.kde.org:websites/kde-org.git
L10NSCRIPTSCHECKOUT="/home/bshah/src/Websites/scripts"    # svn+ssh://svn@svn.kde.org/home/kde/trunk/l10n-kde4/scripts/
WWWCHECKOUT="/home/bshah/src/Websites/kde-org"                     # git@invent.kde.org:websites/kde-org.git
UPLOADSERVER="ftpadmin@master.kde.org"
#UPLOADSERVER="weegie"

RELEASEDATE="Tuesday, 22 September 2020" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEMONTH="September" # usually `LC_ALL=C date "+%B" --date="next Tue"`
TIMESINCELASTRELEASE="a month's" # in sentence 'This release adds TIMESINCELASTRELEASE worth of new'

SCRATCH_SERVER=bshah.in:/tmp/ # somewhere to scp QA and tag files to

YOUTUBEID="https://peertube.mastodon.host/videos/embed/8de9155b-a080-4997-9340-f997312b917e" # The video ID used in URL for youtube

# command from   git clone kde:jriddell/appstream-metainfo-release-update
APPSTREAM_UPDATER="/home/bshah/src/appstream-metainfo-release-update/appstream-metainfo-release-update"

GPG_KEY=0xFE0784117FBCE11D
RELEASE_DUDE="Bhushan Shah"
