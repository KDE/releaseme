<!--
    SPDX-License-Identifier: CC0-1.0
    SPDX-FileCopyrightText: 2017 Harald Sitter <sitter@kde.org>
-->

You really really really really should not use this!

# I MEAN IT DO NOT USE THIS!

See the main README.md for information on how to use repo-metadata for 99% of
use cases.
If you find that you want to use a project config because you cannot make the
automated data match your expecation you PARTICULARLY should NOT use a config
unless you absolutely know what you are doing. If the data determined by
releaseme seems off it is more than likely that your project is not properly
configured for release and overriding the data will only give you a subpar
tarball, whilest not addressing the underlying problem. Read up on the main
readme and the repo-metadata's readme and try to find someone to help you with
getting this fixed (e.g. file a sysadmin ticket or send a mail to
kde-devel@kde.org).

# Projects Config

A projects config file can be used to bypass the automatically determined
information from KDE's project metadata. Its format is largely subject to
change as it represents properties of the object representation in
releaseme internally.

The config file is written in yaml, its properties are equal to the properties
of the Project class. For in-depth information on the de-serialiation check the
code of `Project.from_config`. Generally the first level properties of Project
need to be defined as regular YAML primitives. Complex classes are nested YAML
objects and get manually deserialized. Abstract complex classes (e.g. a VCS has
multiple possible concrete types) have a pseudo `type` property defining the
class name of its concrete type.

Example (may be out of date):

```
identifier: plasma-mediacenter
vcs:
    type: Git
    repository: kde:plasma-mediacenter
i18n_trunk: master
i18n_stable: Plasma/5.7
i18n_path: 'kde-workspace'
```

This would end up in a tarball plasma-mediacenter-x.y.tar.xz when run through
tarme. It would fetch from `kde:plasma-mediacenter` and get i18n data from
SVN from the i18n directory `kde-workspace`.

Do note that when running tarme with --from-config the name you specify is the
name of the config rather than the identifier in the config, to that end you
can `tarme foobar` but get a tarball `barfoo.tar` as the identifier is what
releaseme internally calls this "thing".
