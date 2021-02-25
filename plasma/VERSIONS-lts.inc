# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2015-2021 Jonathan Riddell <jr@jriddell.org>
# SPDX-FileCopyrightText: 2016 David Edmundson <kde@davidedmundson.co.uk>
# SPDX-FileCopyrightText: 2020 Carl Schwan <carl@carlschwan.eu>

LANG=en_GB.UTF-8
LANGUAGE=en
LC_ALL=en_GB.UTF-8

VERSION=5.18.6
SHORT_VERSION=5.18
OLD_VERSION=5.18.5
ORIGIN=lts  # git branch as set in projects.k.o, set to trunk or stable or lts
FTPSTABLE=stable  # set to unstable or stable
OLD_FTPSTABLE=stable  # set to unstable or stable of previous release
BRANCH=Plasma/5.18 # set to master or Plasma/5.x
MINOR_RELEASE_MONTH="February 2020" # for announcement, when was 5.x.0 released

RELEASETYPE=Bugfix # for changelog, set to beta, feature or bugfix

INFOCHECKOUT=/home/jr/src/Websites/kde-org/info                   # git@invent.kde.org:websites/kde-org.git
ANNOUNCECHECKOUT=/home/jr/src/Websites/kde-org/announcements  # git@invent.kde.org:websites/kde-org.git
L10NSCRIPTSCHECKOUT=/home/jr/src/Websites/l10n-kf5/scripts    # svn+ssh://svn@svn.kde.org/home/kde/trunk/l10n-kde4/scripts/
WWWCHECKOUT=/home/jr/src/Websites/kde-org                     # git@invent.kde.org:websites/kde-org.git
UPLOADSERVER="ftpadmin@master.kde.org"
#UPLOADSERVER="weegie"

RELEASEDATE="Tuesday, 29 September 2020" # usually  `LC_ALL=C date "+%A, %d %B %Y" --date="next Tue"`
RELEASEMONTH="September" # usually `LC_ALL=C date "+%B" --date="next Tue"`
TIMESINCELASTRELEASE="six months'" # in sentence 'This release adds TIMESINCELASTRELEASE worth of new'

SCRATCH_SERVER=embra:tmp/ # somewhere to scp QA and tag files to

YOUTUBEID="https://peertube.mastodon.host/videos/embed/cda402b5-2bcb-4c0c-b232-0fa5a4dacaf5" # The video ID used in URL for youtube

# command from   git clone invent:sysadmin/appstream-metainfo-release-update
APPSTREAM_UPDATER="~/src/appstream-metainfo-release-update/appstream-metainfo-release-update/appstream-metainfo-release-update"

GPG_KEY=EC94D18F7F05997E
RELEASE_DUDE="Jonathan Riddell"
