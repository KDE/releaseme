# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2015-2021 Jonathan Riddell <jr@jriddell.org>
# SPDX-FileCopyrightText: 2019 Harald Sitter <sitter@kde.org>
# SPDX-FileCopyrightText: 2020 Bhushan Shah <bhush94@gmail.com>
# SPDX-FileCopyrightText: 2020 Carl Schwan <carl@carlschwan.eu>

MAJOR_VERSION=5
VERSION=5.23.0
SHORT_VERSION=5.23
OLD_VERSION=5.22.5
ORIGIN=stable # git branch as set in projects.k.o, set to trunk or stable or lts
FTPSTABLE=stable  # set to unstable or stable
OLD_FTPSTABLE=stable  # set to unstable or stable of previous release
BRANCH=Plasma/5.23 # set to master or Plasma/5.x

RELEASETYPE=feature # for changelog, set to beta, feature or bugfix

INFOCHECKOUT="/home/jr/src/Websites/kde-org/content/info"                   # git@invent.kde.org:websites/kde-org.git
ANNOUNCECHECKOUT="/home/jr/src/Websites/kde-org/content/announcements"  # git@invent.kde.org:websites/kde-org.git
L10NSCRIPTSCHECKOUT="/home/jr/src/sysadmin/l10n-scripty"    # git clone git@invent.kde.org:sysadmin/l10n-scripty.git
WWWCHECKOUT="/home/jr/src/Websites/kde-org"                     # git@invent.kde.org:websites/kde-org.git
UPLOADSERVER="ftpadmin@deino.kde.org"
#UPLOADSERVER="weegie"

RELEASEDATE="Thursday, 14 October 2021" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEDATEISO="2021-10-14" # usually  `LC_ALL=C date "+%Y-%m-%d" --date="next Tue"`

#SCRATCH_SERVER=bshah.in:/tmp/ # somewhere to scp QA and tag files to
SCRATCH_SERVER=embra:tmp/ # somewhere to scp QA and tag files to
SCRATCH_SERVER_URL=http://embra.edinburghlinux.co.uk/~jr/tmp # URL to view this

VIDEO_KEY="youtube" # type of video: "youtube", "peertube", "video"
VIDEO_VALUE="HdirtBXW8bI" # The video ID used in URL for "youtube" and "peertube", and "true" for "video"

# command from   git clone invent:sysadmin/appstream-metainfo-release-update
APPSTREAM_UPDATER="/home/jr/src/appstream-metainfo-release-update/appstream-metainfo-release-update/appstream-metainfo-release-update"

GPG_KEY=D7574483BB57B18D
RELEASE_DUDE="Jonathan Esk-Riddell"

BROWSER=firefox  # chromium, firefox etc
