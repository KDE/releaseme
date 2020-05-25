[![pipeline status](https://invent.kde.org/sdk/releaseme/badges/master/pipeline.svg)](https://invent.kde.org/sdk/releaseme/-/commits/master)
[![coverage report](https://invent.kde.org/sdk/releaseme/badges/master/coverage.svg)](https://invent.kde.org/sdk/releaseme/-/commits/master)
[![Inline docs](http://inch-ci.org/github/apachelogger/releaseme.svg?branch=master)](http://inch-ci.org/github/apachelogger/releaseme/branch/master)

Releaseme is a release tool for software hosted on KDE infrastructure. It takes care of the nitty gritty details of creating a high-quality release tarball.

```
git clone kde:releaseme
cd releaseme
./tarme.rb --version 1.0 --origin trunk libdebconf-kde
```

For more details on how to make a release see
https://community.kde.org/ReleasingSoftware

## KDELibs 4.x

The `master` branch only supports KDE Frameworks based releases. To release for
KDELibs 4.x please use the `kdelibs4` branch. This in particular also applies
to software that has its translations in the kdelibs4 directories on SVN.

## KDE Frameworks 5.x

Releaseme uses 'origins' to control which branch to release and where to draw
translations from. An origin is basically the i18n association as configured in:
https://phabricator.kde.org/source/sysadmin-repo-metadata/
It is imperative that you make sure the data configured there is
correct and up to date!

### Requirements

- SSH needs to be configured correctly to push to KDE. Currently this also
  applies to non-push operations such as tarball creation.
- Appropriate Ruby version (You'll be informed if your version is not supported)
- Various CLI tools (You'll be informed if one is missing. There is however no
  advanced version checking in place, so you probably want to use whatever is
  latest to avoid issues).

### Tarballing

The corner stone script to create a tarball is tarme.rb.

Tarme requires three arguments

- **origin**: either trunk or stable referring to the i18n branch configured in
  https://phabricator.kde.org/source/sysadmin-repo-metadata/
- **version**: the version you wish to release
- The name of the project you want to release. This technically can be the
  full path in https://phabricator.kde.org/source/sysadmin-repo-metadata/browse/master/projects/
  (e.g. kde/workspace/ksysguard) but does not need to be in most cases as
  tarme will try to figure this out for itself.

Tarme creates a tarball in the present working directory as well as release meta
data file. Latter will in turn be used by other scripts to operate on the same
revisions etc..

You can call tarme as well as all other scripts from a different working
directory in order to make it write the data into a specific directory.

### Tagging

Once you have a suitable tarball you can use tagme to create a release tag.

### Branching

If you wish to create a stable branch off the revision you released you can use
branchme.

## General Release Workflow

- Decide on a release date (duh)
- Decide on a string freeze time frame before the release. This freeze should be
  upwards of 7 days before a release. For most medium sized projects a freeze of
  14 days is recommendable.
- When string freeze draws closer make sure the correct branches are set for
  i18n trunk or i18n stable (depending on what you want to release) in
  https://phabricator.kde.org/source/sysadmin-repo-metadata/.
  When you change the i18n settings also make sure to inform the
  translators of the move either on IRC or by mail at kde-i18n-doc@kde.org
- Inform the translation teams when you start string freeze and tell them when
  the release is due so they can plan accordingly. kde-i18n-doc@kde.org
- On release day run tarme with the correct origin and version
- Verify the tarball and do a test build, possibly ask peers to build on their
  systems as well.
- Upload to ftp://upload.kde.org/ and note the README in there.
- File a ticket with the sysadmins to move your tarball into a suitable place on
  http://download.kde.org. If you are unsure about where to put it you can
  ask the release-team@kde.org for some guidance.
  In the ticket, provide both SHA-1 and SHA-256 checksums for the tarball.
- Run tagme to tag your release in git.
- Once the sysadmins have processed your ticket announce the release in whatever
  way that seems reasonable (blog post, dot.kde.org, kde-announce-apps@kde.org,
  twitter, facebook, g+ etc. etc. etc.)

## Best Practise

- No backsies! Once you published your tarball (that is: as soon as it hits
  download.kde.org publically) you have to increase the version number.
  This can be as trivial as simply appending a new position with .1 e.g.:
  2.0.0 becomes 2.0.0.1
- Use discrete version numbers. No -beta or whatever suffixes. Use appropriately
  large version numbers to represent the pre-release status.
  A common scheme employed is to use .7x for alpha, .8x for beta, .9x for rc.
  So for example 5.1 alpha1 would be 5.0.71.
- Do not use any random non-digit suffixes to versions! Always stick to digits
  and points only!
  No 2.0.0-1, no 2.0.0a, no 2.0.0-beta, no 2.0.0alpha, no 2.0.0.real, etc.
- tarme -> check results -> tagme. You really should not tag unless you are
  sure your tar is of suitable quality.
- Always provide the full GPG finger print (short ids can be collided with
  relatively little effort)
- Make sure you provide the finger print via a trusted source (i.e. HTTPs, not
  unsigned mails etc.)
- Also check over https://community.kde.org/ReleasingSoftware#Sanity_Checklist

## CI State

Releaseme automatically checks build.kde.org for relevant jobs and complains if
one of them doesn't have a stable build (i.e. a green one) as most recent
build. You can lower the required quality by exporting
`RELEASEME_CI_CHECK=success` (i.e. yellow). You really should not ever release
your software if the CI jobs aren't building at all. You are flying blind at
that point.

## Translations

Releaseme automatically tries to grab translations and documentation translation
from the data it can find in the repo-metadata. It also tries to automatically
wire up CMake to build both. If you need the CMake code block placed at a
specific place in your root CMakeLists.txt you can use a place holder macro to
tell releaseme where to put its code. `#PO_SUBDIR`.

NOTE: releaseme will try to be smart and only add the code block when it isn't
already there. So you can actually use ki18n_install(po) in a conditional and
releaseme will not add another one.

## Issues

If you are problems or suggestions file a bug report in bugzilla:
https://bugs.kde.org/enter_bug.cgi?product=releaseme

## Signing | GPG

For background info on tarball signing take a look at the [GPG page](GPG.md)

## Hacking ReleaseMe

[Check out the contributor's page](Contributing.md)
