VERSION=5.20.1
SHORT_VERSION=5.20
OLD_VERSION=5.20.0
ORIGIN=stable  # git branch as set in projects.k.o, set to trunk or stable or lts
FTPSTABLE=stable  # set to unstable or stable
OLD_FTPSTABLE=stable  # set to unstable or stable of previous release
BRANCH=Plasma/5.20 # set to master or Plasma/5.x
MINOR_RELEASE_MONTH="October 2020" # for announcement, when was 5.x.0 released

RELEASETYPE=bugfix # for changelog, set to beta, feature or bugfix

INFOCHECKOUT="/home/jr/src/Websites/kde-org/content/info"                   # git@invent.kde.org:websites/kde-org.git
ANNOUNCECHECKOUT="/home/jr/src/Websites/kde-org/content/announcements"  # git@invent.kde.org:websites/kde-org.git
L10NSCRIPTSCHECKOUT="/home/jr/src/Websites/l10n-kf5/scripts"    # svn+ssh://svn@svn.kde.org/home/kde/trunk/l10n-kde4/scripts/
WWWCHECKOUT="/home/jr/src/Websites/kde-org"                     # git@invent.kde.org:websites/kde-org.git
UPLOADSERVER="ftpadmin@master.kde.org"
#UPLOADSERVER="weegie"

RELEASEDATE="Tuesday, 20 October 2020" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEMONTH="October" # usually `LC_ALL=C date "+%B" --date="next Tue"`
TIMESINCELASTRELEASE="a week's" # in sentence 'This release adds TIMESINCELASTRELEASE worth of new'

#SCRATCH_SERVER=bshah.in:/tmp/ # somewhere to scp QA and tag files to
SCRATCH_SERVER=embra:tmp/ # somewhere to scp QA and tag files to

YOUTUBEID="https://cdn.kde.org/promo/Announcements/Plasma/5.20/Video.webm" # The video ID used in URL for youtube

# command from   git clone invent:sysadmin/appstream-metainfo-release-update
APPSTREAM_UPDATER="/home/jr/src/appstream-metainfo-release-update/appstream-metainfo-release-update/appstream-metainfo-release-update"

GPG_KEY=EC94D18F7F05997E
RELEASE_DUDE="Jonathan Riddell"

BROWSER=chromium  # chromium, firefox etc
