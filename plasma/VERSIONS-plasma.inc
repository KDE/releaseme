# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2015-2021 Jonathan Riddell <jr@jriddell.org>
# SPDX-FileCopyrightText: 2019 Harald Sitter <sitter@kde.org>
# SPDX-FileCopyrightText: 2020 Bhushan Shah <bhush94@gmail.com>
# SPDX-FileCopyrightText: 2020 Carl Schwan <carl@carlschwan.eu>

PRODUCT="plasma" # frameworks or plasma

MAJOR_VERSION=6
VERSION=6.4.0
NEXT_VERSION=6.4.0 # what will the next release be for ./update-verions --next
SHORT_VERSION=6.4.0 # the directory to use on ftpadmin
BRANCH_VERSION=6.4 # the version part to use in the Plasma/6.x branch name
OLD_VERSION=6.3.5
ORIGIN=stable # git branch as set in projects.k.o, set to trunk or stable or lts
FTPSTABLE=stable  # set to unstable or stable
OLD_FTPSTABLE=stable  # set to unstable or stable of previous release for changelog
BRANCH=Plasma/6.4 # set to master or Plasma/6.x

RELEASETYPE=feature # for changelog, set to beta, feature or bugfix

# git@invent.kde.org:websites/kde-org.git
WWWCHECKOUT="/home/bshah/src/Websites/kde-org"
UPLOADSERVER="ftpadmin@tinami.kde.org"
#UPLOADSERVER="embra"

RELEASEDATE="Thursday, 17 June 2025" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEDATEISO="2025-06-17" # usually  `LC_ALL=C date "+%Y-%m-%d" --date="next Tue"`

SCRATCH_SERVER=bshah.in:/tmp/ # somewhere to scp QA and tag files to
SCRATCH_SERVER_URL=http://embra.edinburghlinux.co.uk/~jr/tmp # URL to view this

VIDEO_KEY="video" # type of video: "youtube", "peertube", "video"
VIDEO_VALUE="false" # The video ID used in URL for "youtube" and "peertube", and "true" for "video"

# command from   git clone invent:sysadmin/appstream-metainfo-release-update
APPSTREAM_UPDATER="/home/bshah/src/Projects/KDE/appstream-metainfo-release-update/appstream-metainfo-release-update"

GPG_KEY=0AAC775BB6437A8D9AF7A3ACFE0784117FBCE11D
RELEASE_DUDE="Bhushan Shah"

BROWSER=firefox  # chromium, firefox etc
