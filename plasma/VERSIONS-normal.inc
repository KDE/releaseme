# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2015-2021 Jonathan Riddell <jr@jriddell.org>
# SPDX-FileCopyrightText: 2019 Harald Sitter <sitter@kde.org>
# SPDX-FileCopyrightText: 2020 Bhushan Shah <bhush94@gmail.com>
# SPDX-FileCopyrightText: 2020 Carl Schwan <carl@carlschwan.eu>

PRODUCT="frameworks"

MAJOR_VERSION=6
VERSION=5.248.0
NEXT_VERSION=5.249.0 # what will the next release be for ./update-verions --next
SHORT_VERSION=6.0
OLD_VERSION=5.247.0
ORIGIN=trunk # git branch as set in projects.k.o, set to trunk or stable or lts
FTPSTABLE=unstable  # set to unstable or stable
OLD_FTPSTABLE=unstable  # set to unstable or stable of previous release for changelog
BRANCH=master # set to master or Plasma/5.x

RELEASETYPE=RC # for changelog, set to beta, feature or bugfix

INFOCHECKOUT="/home/jr/src/websites/kde-org/content/info"                   # git@invent.kde.org:websites/kde-org.git
ANNOUNCECHECKOUT="/home/jr/src/websites/kde-org/content/announcements"  # git@invent.kde.org:websites/kde-org.git
L10NSCRIPTSCHECKOUT="/home/jr/src/sysadmin/l10n-scripty"    # git clone git@invent.kde.org:sysadmin/l10n-scripty.git
WWWCHECKOUT="/home/jr/src/websites/kde-org"                     # git@invent.kde.org:websites/kde-org.git
UPLOADSERVER="ftpadmin@tinami.kde.org"
#UPLOADSERVER="weegie"

RELEASEDATE="Wednesday, 10 January 2023" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEDATEISO="2024-01-10" # usually  `LC_ALL=C date "+%Y-%m-%d" --date="next Tue"`

#SCRATCH_SERVER=bshah.in:/tmp/ # somewhere to scp QA and tag files to
SCRATCH_SERVER=embra:tmp/ # somewhere to scp QA and tag files to
SCRATCH_SERVER_URL=http://embra.edinburghlinux.co.uk/~jr/tmp # URL to view this

VIDEO_KEY="video" # type of video: "youtube", "peertube", "video"
VIDEO_VALUE="false" # The video ID used in URL for "youtube" and "peertube", and "true" for "video"

# command from   git clone invent:sysadmin/appstream-metainfo-release-update
APPSTREAM_UPDATER="/home/jr/src/sysadmin/appstream-metainfo-release-update/appstream-metainfo-release-update"

GPG_KEY=E0A3EB202F8E57528E13E72FD7574483BB57B18D
RELEASE_DUDE="Jonathan Esk-Riddell"

BROWSER=firefox  # chromium, firefox etc
