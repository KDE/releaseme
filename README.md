[![Build Status](https://travis-ci.org/apachelogger/releaseme.svg?branch=master)](https://travis-ci.org/apachelogger/releaseme)
[![Coverage Status](https://coveralls.io/repos/apachelogger/releaseme/badge.svg?branch=master)](https://coveralls.io/r/apachelogger/releaseme?branch=master)
[![Code Climate](https://codeclimate.com/github/apachelogger/releaseme/badges/gpa.svg)](https://codeclimate.com/github/apachelogger/releaseme)
[![PullReview stats](https://www.pullreview.com/github/apachelogger/releaseme/badges/master.svg?)](https://www.pullreview.com/github/apachelogger/releaseme/reviews/master)
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

tarme will force sign the tarballs it creates. There is no option to disable
this and there won't be one.

tagme will sign the tags it creates, this is however of a more opt-in nature.

### Why?

KDE tarballs are largely distributed through a mirror network. These mirrors
then often distribute the tarballs over HTTP or FTP connections, both of which
are fairly susceptible to man-in-the-middle attacks where a blackhat hijacks the
users traffic and makes the user download a malicious tarball or view a website
with incorrect data. Checksums help with this to a degree, GPG signatures are
however the far superior option due to cryptographic keys and the web of trust,
which act as an add-on to what a checksum provide.

### Example

If you are releasing foobar-1.0 it has the checksum AABBCC. To tell your users,
and most importantly your packagers that this is the checksum, you have to send
them a mail or publish this on a website. Unless you GPG sign this mail and
force the website to use HTTPS both are just as insecure as the tarball is.
Assuming you don't actually mention the checksum in the mail but point to
your HTTPS secured website, you make it infinitely harder for packagers to
automatically pull in your new release as they have to go to some website to
get a checksum.
After a while you may release foobar-2.0, and update the checksum. During 1.0
and 2.0 the website server may have been compromised and a blackhat may now
feed people his malicious checksum along with his malicious tarball. Until you
find out that the website has been compromised no one would know.

GPG signing helps with this on two fronts.

- The signature is an opt-in file the user can easily download (automatically)
  and verify (automatically)
- You only need to tell the user your key fingerprint once, they can verify it
  once and any future release is sorted as long as you don't use a new key.
  Should your website and tarball get compromised they won't match the key
  expectation anymore and raise flags.

### Advantages

- Worst case the .sig file generated is a glorified checksum helper, as gpg can
  verify that the signature matches, even if the key doesn't. And the signature
  only matches if the file is pristine.
- If you have a new key the user may simply trust-on-first-use, at this point
  they are no less secure than if there was no key. Moving forward with every
  release the trustworthyness of your key naturally increases though.
- If you choose to have your key cross-signed (other KDE release managers and
  developers are a good starting point) you can build a web of trust around your
  key. This enables advanced GPG users to not trust-on-first-use only but
  add additional (more implicit) checks.
- A lot of distributions already have systems in place to automatically verify
  GPG signatures at build time. This enables a higher level of security and trust
  between you and the distribution, ultimately improving the overall security
  the users of the distribution can expect as well.

### Web of Trust

A web of trust is the distributed trustworthyness of a key. GPG keys can sign
other keys. The ideal scenario of trust is when the user has signed your signing
key. In this case the user has verified that you are you by means of meeting you
in real life. Since this is the least likely scenario you'll want to have a good
web though. The idea is that inside the web you have between 0 and N edges to
go before your key is connected to the user's key. The less edges, the more
trustworthy your key is. As an example... I signed Jonathan Riddell's key, since
I verified his key. Jonathan in turn signed David Faure's key, since he verified
his key. As a result I can very likely trust David Faure's release tarballs as
being authentic even though I personally never verified David's key as being
legit.

### Getting Started

There's lots of great documention on GPG a very techy getting started guide is
available on gnupg.org https://www.gnupg.org/gph/en/manual/c14.html

Generally all you need to do to get started with signing is you need to
generate a key. Going with the gpg suggested defaults is usually a good idea.
Once you have that you can start signing releases and read up on how to build
a web of trust around your key.

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

Tests are done using test-unit.

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

#### Dependencies

Unlike the actual library the testing rig requires third party libraries
(AKA gems) to run. So you'll want to get them installed. In the Ruby world we
use a tool called bundler for this. So you'll want to install bundler through
Ruby's built-in gem manager and then in the source directory instruct bundler
to install the dependencies:

```
gem install bundler
bundler install
```

This installs a fixed set of dependencies locked to a specific version.

NOTE: the built-in gem manager is itself a gem and may need updating every
once in a while with `gem update --system`. In particular when switching to
newer Ruby versions.

#### Testing

Testing is simply done by running: `rake test`

#### Bumping Ruby versions

Releaseme is tightly version locked to Ruby, meaning it will only work with
versions we know it works on. This in particular is so that we know someone
ran the tests at least once and thus that the Ruby version is able to generate
the expected results. Ruby, being a runtime interpreted language, can change in
ways that have the potential to generate broken release tarballs. As we
absolutely do not want that the version safe guard is in place.

To bump the version restriction you need to at the very least run `rake test`
and make sure it passes on that version. This will at least need you to update
the requirement_checker and its associated test. In addition to that it may be
necessary to update gems to iron out incompatibilities with `bundle update`.

Finally, please make sure that at least the .0 variant of the new Ruby version
is listed in .travis.yml.
