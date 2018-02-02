## Hacking ReleaseMe

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
