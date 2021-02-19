<!--
    SPDX-License-Identifier: CC0-1.0
    SPDX-FileCopyrightText: 2019 Harald Sitter <sitter@kde.org>
-->

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
