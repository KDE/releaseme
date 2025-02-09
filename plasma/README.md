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

 -  Check for critical bugs: https://bugs.kde.org/buglist.cgi?bug_severity=critical&bug_status=UNCONFIRMED&bug_status=CONFIRMED&bug_status=ASSIGNED&bug_status=REOPENED&classification=Applications&classification=Plasma&classification=I%20don%27t%20know&f1=creation_ts&f2=bug_status&list_id=2833481&o1=changedafter&o2=anyexact&product=Active&product=Active%20Window%20Control&product=Bluedevil&product=Breeze&product=colord-kde&product=Discover&product=drkonqi&product=homerun&product=kactivitymanagerd&product=kde&product=kde-cli-tools&product=kde-gtk-config&product=kde-inotify-survey&product=kdeplasma-addons&product=Keyboard%20status%20applet&product=kgamma&product=khotkeys&product=kicker&product=kinfocenter&product=kiosk&product=krunner&product=KScreen&product=kscreenlocker&product=ksmserver&product=ksplash&product=kstart&product=kwayland-integration&product=kwin&product=kwin4&product=kwintv&product=lattedock&product=Mangonel&product=Ocean&product=Plasma%20Camera%20Indicactor%20Applet&product=Plasma%20SDK&product=Plasma%20Vault&product=Plasma%20Workspace%20Wallpapers&product=plasma-browser-integration&product=plasma-disks&product=plasma-integration&product=plasma-nm&product=plasma-pa&product=plasma-systemmonitor&product=plasma-wayland-protocols&product=plasmashell&product=policykit-kde-agent-1&product=Powerdevil&product=printer-applet&product=pulseaudio-qt&product=system-config-printer-kde&product=Systemd%20KCM&product=systemdgenie&product=systemsettings&product=systemsettings-kde3&product=Touchpad-KCM&product=user-manager&product=wacomtablet&product=Welcome%20Center&product=xdg-desktop-portal-kde&query_format=advanced
 -  Update git-repos and generate git-repositories-for-release-plasma then e-mail out list of repos you plan to package and highlight any differences to last release

Tars get made and release same day for beta releases, bugfix releases but not .0 releases.  Beta also has some extra steps as well as the tar making steps.

## On Beta day (setting versions)
 - Add release exceptions array to ./git-repos and run "./git-repos -r 6.xx" to update list of things to package in git-repositories-for-release
 - set QT_VERSION and KF5_VERSION in ./plasma-update-versions-qtkf and run that script to set version agreed at cycle kickoff (make sure to check the exceptions)
 - Edit and run add-bugzilla-versions to add a new version git-stable-Plasma/6.xx
 - Update bug closing bot versions at https://invent.kde.org/sysadmin/bugzilla-bot/-/blob/master/data/versions.yml
 - Check if a new release of plasma-wayland-protocols is needed and make it
 - Bump the version of plasma-wayland-protocols in CMakeLists.txt of kwayland, powerdevil and other users

## On Tar days (making tars)
 - update VERSIONS.inc
 - run ./update-versions to update the DEP version to the current one and add to Appstream files
 - run ./make-release-tars script to make tars
 - check tmp-tests output for important differences
 - run ./update-web-git  which will make a new branch e.g. work/plasma-6-1-1
 - run ./upload-tars
 - run ./plasma-update-1-tar as needed for problems/late updates # TODO make this print out git log changes
 - (or upload to upload.kde.org and tell sysadmins to make tars available to packagers if you do not have permission)

## On Beta day (making branches)
 On a new 6.x release make branches Plasma/6.x after making the tars

 - run ./make-branch for Plasma (but not Frameworks)
 - edit ./update-versions to override versions to set 6.x.80 and run it for master
 - ping tosky and kde-i18n-doc@kde.org list to branch messages and docmessages and update repo-metadata
 - E-mail plasma-devel@kde.org with the happy news of new Plasma/6.x branches
 - Update https://community.kde.org/Plasma/Live_Images

## On tar day (prepare)
 - run ./make-changelog (manually edit file after)  TODO extract bug report title
 - run ./make-webpages [-n] and check over output opened in firefox (use -n for noannounce on e.g. .0 releases where the announce is written manually)
 - run cwebp on the images to convert to WebP and update URLs https://developers.google.com/speed/webp
 - run ./add-bugzilla-versions to update bugzilla version numbers (needs curl installed and may need bugzilla-cookies.inc updated)
 - tell release-team@kde.org, plasma-devel@kde.org
 - tell VDG and Plasma team about announce and get feedback

## On release day (launch)
 - ./push-tags to push tags
 - ./pushed-tags-test to check the tags are really pushed
 - ./make-release
 - this will open tabs in firefox and kate: check the web pages are good, e-mail out the texts, post the social media bits
 - run ./update-versions --next to update the version ahead of the next release
 - check if www/images/teaser teaser image needs an update
 - for feature release schedule a kickoff meeting for next feature release for scheduling and feature planning
 - for beta releases also copy announce to 5.x.0 page and poke Paul etc to do a final one then ask for translations
 - For .0 update bug closing bot versions at https://invent.kde.org/sysadmin/bugzilla-bot/-/blob/master/data/versions.yml
 - For .0 update invent:websites/kde-org plasma-desktop.php screenshots/index.php and invent:websites/product-screenshots plasma/plasma.png  for new version
 - For .0 update invent:websites/aether-sass /css/kde-org/plasma-desktop.scss and assets/wallpaper.jpg for new wallpaper
 - For LTS .0 release edit and run ./plasma-bugzilla-versions to set beta .90 version and versions prior to the old old LTS release to inactive (we like to allow people to select the version they are using so if in doubt keep it enabled)

 - (For Plasma .0 tell a KDE neon person to update forks/base-files and neon/settings (release-lts only) to show new version before running 'jenking_retry -p' and making ISOs and Docker)

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
 - Frameworks pushed tags with v5.100.0-rc1 on packaging then any plasma-update-1-tar calls should use that tag and local branch and a cherry-pick (or master) and push v5.100.0-rc2 see ./make_rc_tag.sh and ./make_updated_tarball.sh, port into plasma-update-1-tar
 - consider a script to update copyright years for KAboutData in Plasma
 - make-changelog has a Jonathan specific path in it for git repos
 - create_log is python2
 - create_log hardcodes which repos list
 - frameworks changelog links fix
 - create_log needs to use the right git-repos file
 - changelog add headers
 - for Plasma do not update ECM version when running update-version for breeze-gtk and breeze-plymouth
 - OLD_VERSION for frameworks needs to be 6.x for upload-tars and 6.x.0 for make-changelog
