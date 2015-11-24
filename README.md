# THE ULTIMATE EXTRAGEAR RELEASE SCRIPT

## Getting Started

- cp example.rb yourthing.rb
- cp examplerc yourthingrc
- Edit both files
- Make sure to edit in the rc
  - customsrc should be the url/uri of your repository
  - gitbranch is the branch you want sources from
  - branch should be the i18n branch you want translations from
  - protocol must remain unchanged!
- Make sure to edit in the rb (see comment)
  - NAME
  - COMPONENT
  - SECTION

## Releasing

```
./yourthing.rb --version 1.0.0
```

You'll find a tarball in your PWD if there are no errors.

## Help

```
./yourthing.rb --help
```

If you are having problems port your software to KF5 and use the master branch
of releaseme. /s
