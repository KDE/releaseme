# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2015-2021 Jonathan Riddell <jr@jriddell.org>
# SPDX-FileCopyrightText: 2016 David Edmundson <kde@davidedmundson.co.uk>
# SPDX-FileCopyrightText: 2020 Carl Schwan <carl@carlschwan.eu>

LANG=en_GB.UTF-8
LANGUAGE=en
LC_ALL=en_GB.UTF-8

MAJOR_VERSION=5
VERSION=5.18.7
SHORT_VERSION=5.18
OLD_VERSION=5.18.6
ORIGIN=lts  # git branch as set in projects.k.o, set to trunk or stable or lts
FTPSTABLE=stable  # set to unstable or stable
OLD_FTPSTABLE=stable  # set to unstable or stable of previous release
BRANCH=Plasma/5.18 # set to master or Plasma/5.x

RELEASETYPE=Bugfix # for changelog, set to beta, feature or bugfix

INFOCHECKOUT="/home/jr/src/Websites/kde-org/content/info"                   # git@invent.kde.org:websites/kde-org.git
ANNOUNCECHECKOUT="/home/jr/src/Websites/kde-org/content/announcements"  # git@invent.kde.org:websites/kde-org.git
L10NSCRIPTSCHECKOUT="/home/jr/src/sysadmin/l10n-scripty"    # git clone git@invent.kde.org:sysadmin/l10n-scripty.git
WWWCHECKOUT="/home/jr/src/Websites/kde-org"                     # git@invent.kde.org:websites/kde-org.git
UPLOADSERVER="ftpadmin@deino.kde.org"
#UPLOADSERVER="weegie"

RELEASEDATE="Tuesday, 30 March 2020" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEDATEISO="2021-03-30" # usually  `LC_ALL=C date "+%Y-%m-%d" --date="next Tue"`

SCRATCH_SERVER=embra:tmp/ # somewhere to scp QA and tag files to
SCRATCH_SERVER_URL=http://embra.edinburghlinux.co.uk/~jr/tmp # URL to view this

VIDEO_KEY="youtube" # type of video: "youtube", "peertube", "video"
VIDEO_VALUE="ahEWG4JCA1w" # The video ID used in URL for "youtube" and "peertube", and "true" for "video"

# command from   git clone invent:sysadmin/appstream-metainfo-release-update
APPSTREAM_UPDATER="/home/jr/src/appstream-metainfo-release-update/appstream-metainfo-release-update/appstream-metainfo-release-update"

GPG_KEY=EC94D18F7F05997E
RELEASE_DUDE="Jonathan Riddell"

BROWSER=firefox  # chromium, firefox etc
