[![Build Status](https://travis-ci.org/apachelogger/releaseme.svg?branch=rewrite)](https://travis-ci.org/apachelogger/releaseme)
[![Coverage Status](https://coveralls.io/repos/apachelogger/releaseme/badge.svg?branch=rewrite)](https://coveralls.io/r/apachelogger/releaseme?branch=rewrite)
[![Code Climate](https://codeclimate.com/github/apachelogger/releaseme/badges/gpa.svg)](https://codeclimate.com/github/apachelogger/releaseme)
[![PullReview stats](https://www.pullreview.com/github/apachelogger/releaseme/badges/rewrite.svg?)](https://www.pullreview.com/github/apachelogger/releaseme/reviews/rewrite)
[![Inline docs](http://inch-ci.org/github/apachelogger/releaseme.svg?branch=rewrite)](http://inch-ci.org/github/apachelogger/releaseme/branch/rewrite)

```
git clone kde:releaseme
cd releaseme
./tarme.rb --version 1.0 --origin trunk libdebconf-kde
```

## KDELibs 4.x

The master branch only supports KDE Frameworks based releases. To release for
KDELibs 4.x please use the kdelibs4 branch.

## KDE Frameworks 5.x

Unlike the previous versions of releaseme the KDE Frameworks version tries to
automated as much as possible by defaulting to the meta data provided on
http://projects.kde.org It is therefore imperative that you make sure the data
configured there is correct and up to date!

The KDE Frameworks 5.x version features a set of separate tools to allow more
atomic control over the workflow (when to tag, when to branch etc.)

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
  - **origin**: either trunk or stable referring to the i18n branch configured on
    projects.kde.org
  - **version**: the version you wish to release
  - The name of the project you want to release. This technically can be the
    full path as seen on projects.kde.org (e.g. kde/workspace/ksysguard) but
    does not need to be in most cases as tarme will try to figure this out for
    itself.

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
  i18n trunk or i18n stable (depending on what you want to release) on
  projects.kde.org. If you change the settings also make sure to inform the
  translators of the move either on IRC or by mail at kde-i18n-doc@kde.org
- Inform the translation teams when you start string freeze and tell them when
  the release is due so they can plan accordingly. kde-i18n-doc@kde.org
- On release day run tarme with the correct origin and version
- Verify the tarball and do a test build, possibly ask peers to build on their
  systems as well.
- Upload to ftp://depot.kde.org/ and note the README in there.
- File a ticket with the sysadmins to move your tarball into a suitable place on
  http://download.kde.org. If you are unsure about where to put it you can
  ask the release-team@kde.org for some guidance.
- Run tagme to tag your release in git.
- Once the sysadmins have processed your ticket announce the release in whatever
  way that seems reasonable (blog post, dot.kde.org, kde-announce-apps@kde.org,
  twitter, facebook, g+ etc. etc. etc.)

## Best Practise
- Use discrete version numbers. No -beta or whatever suffixes. Use appropriately
  large version numbers to represent the pre-release status.
  A common scheme employed is to use .7x for alpha, .8x for beta, .9x for rc.
  So for example 5.1 alpha1 would be 5.0.71.
- tarme -> check results -> tagme. You really should not tag unless you are
  sure your tar is of suitable quality.
- No backsies! Once you published your tarball (that is: as soon as it hits
  download.kde.org publically) you have to increase the version number.
  This can be as trivial as simply appending a new position with .1 e.g.:
  2.0.0 becomes 2.0.0.1

## Hacking

Releaseme is entirely written in Ruby.

All code in releaseme is meant to not use external gems as to not enable
people to fall on their nose because they didn't want to read the readme :'<.
The one and only exception to this rule are the actual tests as they do not
affect production use anyway.

It is supposed to be 100% unit test covered. And tests are wired up to various
QA and CI services throughout the internet (see badges on github).

Public methods should be documented as much as possible using either yard
format or rdoc (yard preferred).

### Testing

Tests are done using test-unit #oldschoolswag.

All tests should derive from test/lib/testme which adds provisioning for PWD
isolation (i.e. it chdirs into tmpdirs for every test) as well as test fixture
access (i.e. helps with getting the absolute path of test/data/ files).

### Making Changes

- Write a test for your change.
- Update a test if your change affects a test that previously was not strict
  enough or lacking data.
- Write a test for the code you change if it hasn't had a test before.
- If you don't write a test it may happen that you get angry mails.
- If you are not sure about the coverage use **rake test** to get coverage
  output in ./coverage/index.html
- If you are still not sure about the coverage run the relevant test_blackbox_*
  script in test/. They call their related tool and evaluate it's output on a
  global level.
