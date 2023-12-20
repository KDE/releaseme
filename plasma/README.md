<!--
    SPDX-License-Identifier: CC0-1.0
    SPDX-FileCopyrightText: 2014-2021 Jonathan Riddell <jr@jriddell.org>
    SPDX-FileCopyrightText: 2015 Harald Sitter <sitter@kde.org>
    SPDX-FileCopyrightText: 2016 David Edmundson <kde@davidedmundson.co.uk>
-->
# Frameworks and Plasma Release Process

## on dep and repo freeze day:
 - Work with Plasma team and Promo team to make an beta and final announce and get the video going

 - check for build failures on CI: https://build.kde.org/job/Plasma/view/Everything%20-%20kf5-qt5/
 - or for a stable version https://build.kde.org/job/Plasma/view/Everything%20-%20stable-kf5-qt5/
 - check for build failures on neon CI: http://build.neon.kde.org/
 - or for a stable version http://build.neon.kde.org/view/1%20stable%20%E2%9A%9B%20git%20stable/

 -  Check for critical bugs: https://bugs.kde.org/buglist.cgi?bug_severity=critical&bug_status=UNCONFIRMED&bug_status=CONFIRMED&bug_status=ASSIGNED&bug_status=REOPENED&known_name=Plasma5-All-Critical&list_id=1364199&product=Breeze&product=kde-cli-tools&product=kde-gtk-config&product=kded-appmenu&product=kdeplasma-addons&product=kfontview&product=khotkeys&product=kinfocenter&product=klipper&product=kmenuedit&product=knetattach&product=krunner&product=ksmserver&product=ksplash&product=ksshaskpass&product=Plasma%20Vault&product=kstart&product=ksysguard&product=kwin&product=kwrited&product=Discover&product=Plasma%20Workspace%20Wallpapers&product=plasma-mediacenter&product=plasma-nm&product=plasmashell&product=Powerdevil&product=systemsettings&product=Touchpad-KCM&product=user-manager&query_based_on=Plasma5-All-Critical&query_format=advanced
 -  Update plasma-git-repos and generate git-repositories-for-release then e-mail out list of repos you plan to package and highlight any differences to last release

Tars get made and release same day for beta releases, bugfix releases but not .0 releases.  Beta also has some extra steps as well as the tar making steps.

## On Beta day (setting versions)
 - Add release exceptions array to ./plasma-git-repos and run "./plasma-git-repos -r 5.xx" to update list of things to package in git-repositories-for-release
 - set QT_VERSION and KF5_VERSION in ./plasma-update-versions-qtkf and run that script to set version agreed at cycle kickoff (make sure to check the exceptions)
 - Edit and run plasma-bugzilla-versions to add a new version git-stable-Plasma/5.xx
 - Update bug closing bot versions at https://invent.kde.org/sysadmin/bugzilla-bot/-/blob/master/data/versions.yml

## On Tar days (making tars)
 - update VERSIONS.inc
 - run ./update-versions to update the DEP version to the current one
 - run ./release-tars script to make tars
 - check tmp-tests output for important differences
 - run ./plasma-update-web-git
 - run ./plasma-upload
 - run ./plasma-update-1-tar as needed for problems/late updates # TODO make this print out git log changes
 - (or upload to upload.kde.org and tell sysadmins to make tars available to packagers if you do not have permission)

## On Beta day (making branches)
 On a new 5.x release make branches Plasma/5.x after making the tars

 - run ./plasma-branch
 - edit ./plasma-update-versions to override versions to set 5.x.80 and run it for master
 - Update build.kde.org CI https://community.kde.org/Infrastructure/Continuous_Integration_System#Updating_builds_on_switching_the_.22stable.22_branch
 - Increse invent:sysadmin/repo-metadata dependencies/logical-module-structure top use new branch Plasma/5.x and build that branch in build.kde.org
 - Trigger build.kde.org to update build setups to latest kde-build-metadata info:
   - https://build.kde.org/job/Administration/job/DSL%20Job%20Seed/
 - When above has completed start global rebuild
   - https://build.kde.org/view/CI%20Management/job/Global%20Rebuild%20Plasma%20kf5-qt5%20SUSEQt5.10/
   - https://build.kde.org/view/CI%20Management/job/Global%20Rebuild%20Plasma%20kf5-qt5%20FreeBSDQt5.10/
  - build.kde.org CI: log in, switch to "CI Management", run "DSL Job Seed" to make sure any latest build-metadata is picked up,
  - once done trigger "Global Rebuild Plasma stable*" builds, which will first update dependencies to latest needs and then trigger rebuild of any modules
  - ping tosky and kde-i18n-doc@kde.org list to branch messages and docmessages and update repo-metadata
  - Update https://community.kde.org/Plasma/Live_Images

## On tar day (prepare)
 - run ./plasma-changelog (manually edit file after)
   [or run xenon job http://xenon.pangea.pub/job/plasma-releaseme-changelog/ then ./plasma-xenon-download-changelog]
 - Run ./plasma-update-web-git
 - run ./plasma-webpages [-n] and check over output opened in firefox (use -n for noannounce on e.g. .0 releases where the announce is written manually)
 - run cwebp on the images to convert to WebP and update URLs https://developers.google.com/speed/webp
 - run ./plasma-add-bugzilla-versions to update bugzilla version numbers (needs curl installed and may need bugzilla-cookies.inc updated)
 - tell release-team@kde.org, plasma-devel@kde.org
 - tell VDG and Plasma team about announce and get feedback

## On release day (launch)
 - ./plasma-tag to push tags
 - ./plasma-update-web-git
 - ./plasma-tag-test to check the tags are really pushed or run http://xenon.pangea.pub/job/plasma-releaseme-tags-test/ to check tags are really pushed
 - ./plasma-release
 - this will open tabs in firefox and kate: check the web pages are good, e-mail out the texts, post the social media bits
 - run ./update-versions --next to update the version ahead of the next release
 - check if www/images/teaser teaser image needs an update
 - for feature release schedule a kickoff meeting for next feature release for scheduling and feature planning
 - for beta releases also copy announce to 5.x.0 page and poke Paul etc to do a final one then ask for translations
 - For .0 update bug closing bot versions at https://invent.kde.org/sysadmin/bugzilla-bot/-/blob/master/data/versions.yml
 - For .0 update invent:websites/kde-org plasma-desktop.php screenshots/index.php and invent:websites/product-screenshots plasma/plasma.png  for new version
 - For .0 update invent:websites/aether-sass /css/kde-org/plasma-desktop.scss and assets/wallpaper.jpg for new wallpaper
 - For LTS .0 release edit and run ./plasma-bugzilla-versions to set beta .90 version and versions prior to the old old LTS release to inactive (we like to allow people to select the version they are using so if in doubt keep it enabled)

 - (tell a KDE neon person to update forks/base-files and neon/settings (release-lts only) to show new version before running 'jenking_retry -p' and making ISOs and Docker)

## Post Release Bugfix update
 - If you need an update between releases use plasma-update-1-tar-post-release for the tar in question

## TODO
 - remove apt from plasma-release
 - update-web-svn has hardcoded paths src/www
 - check .sig matches the key in VERSION
 - test gpg works with agent before running plasma-tag
 - for 5.16.90 the release_data file had the kscreen info duplicated info libkscreen, why?
 - block running plasma-release unless plasma-tags-test has been run

## TODO Frameworks
 - Update version update to have two steps
 - Frameworks pushed tags with v5.100.0-rc1 on packaging then any plasma-update-1-tar calls should use that tag and local branch and a cherry-pick (or master) and push v5.100.0-rc2 see ./make_rc_tag.sh and ./make_updated_tarball.sh
 - consider updating PROJECT_VERSION in plasma deps to e.g. PROJECT_DEP_VERSION similar to frameworks for CI happiness.  e.g. kscreen should dep on current released version of libkscreen
 - consider a script to update copyright years for KAboutData in Plasma
 - plasma-upload for Frameworks (to upload to ftpadmin, run some checks compared to previous release, and update info page
 - plasma-changelog works ok for frameworks but does need fixes
 - plasma-webpages needs frameworksified
 - ./plasma-add-bugzilla-versions needs frameworksified (for now use ./create_bugzilla_versions.sh)
 - ./plasma-tag needs frameworkified
