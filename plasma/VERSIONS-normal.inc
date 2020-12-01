VERSION=5.20.4
SHORT_VERSION=5.20
SHORT_VERSION_DASH=5-20 # used for plasma webpage template
OLD_VERSION=5.20.3
ORIGIN=stable  # git branch as set in projects.k.o, set to trunk or stable or lts
FTPSTABLE=stable  # set to unstable or stable
OLD_FTPSTABLE=stable  # set to unstable or stable of previous release
BRANCH=Plasma/5.20 # set to master or Plasma/5.x
MINOR_RELEASE_MONTH="October 2020" # for announcement, when was 5.x.0 released

RELEASETYPE=bugfix # for changelog, set to beta, feature or bugfix

INFOCHECKOUT="/home/jr/src/Websites/kde-org/content/info"                   # git@invent.kde.org:websites/kde-org.git
ANNOUNCECHECKOUT="/home/jr/src/Websites/kde-org/content/announcements"  # git@invent.kde.org:websites/kde-org.git
L10NSCRIPTSCHECKOUT="/home/jr/src/Websites/l10n-kf5/scripts"    # svn co svn://anonsvn.kde.org/home/kde/trunk/l10n-kf5/scripts
WWWCHECKOUT="/home/jr/src/Websites/kde-org"                     # git@invent.kde.org:websites/kde-org.git
UPLOADSERVER="ftpadmin@deino.kde.org"
#UPLOADSERVER="weegie"

RELEASEDATE="Tuesday, 1 December 2020" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEMONTH="December" # usually `LC_ALL=C date "+%B" --date="next Tue"`
TIMESINCELASTRELEASE="a month's" # in sentence 'This release adds TIMESINCELASTRELEASE worth of new'

#SCRATCH_SERVER=bshah.in:/tmp/ # somewhere to scp QA and tag files to
SCRATCH_SERVER=embra:tmp/ # somewhere to scp QA and tag files to

YOUTUBEID="https://cdn.kde.org/promo/Announcements/Plasma/5.20/Video.webm" # The video ID used in URL for youtube

# command from   git clone invent:sysadmin/appstream-metainfo-release-update
APPSTREAM_UPDATER="/home/jr/src/appstream-metainfo-release-update/appstream-metainfo-release-update/appstream-metainfo-release-update"

GPG_KEY=EC94D18F7F05997E
RELEASE_DUDE="Jonathan Riddell"

BROWSER=firefox  # chromium, firefox etc
