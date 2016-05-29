<?php
  include_once ("functions.inc");
  $translation_file = "www";
  $page_title = i18n_noop("KDE Plasma 5.6.4, bugfix Release for May");
  $site_root = "../";
  $release = 'plasma-5.6.4';
  include "header.inc";
?>

<?php
  include "./announce-i18n-bar.inc";
?>

<style>
figure {text-align: center; float: right; margin: 0px;}
figure img {padding: 1ex; border: 0px; background-image: none;}
figure video {padding: 1ex; border: 0px; background-image: none;}
figcaption {font-style: italic;}
</style>

<figure style="float: none">
<iframe style="text-align: center" width="560" height="315" src="https://www.youtube.com/embed/v0TzoXhAbxg?rel=0" frameborder="0" allowfullscreen></iframe>
<figcaption><?php i18n("KDE Plasma 5.6 Video");?></figcaption>
</figure>
<br clear="all" />

<figure style="float: none">
<a href="plasma-5.6/plasma-5.6.png">
<img src="plasma-5.6/plasma-5.6-wee.png" style="border: 0px" width="600" height="338" alt="<?php i18n('Plasma 5.6');?>" />
</a>
<figcaption><?php i18n("KDE Plasma 5.6");?></figcaption>
</figure>

<h1>NOT OUT YET</h1>

<p>
<?php i18n("Tuesday, 10 May 2016. "); ?>
<?php i18n("Today KDE releases a bugfix update to KDE Plasma 5, versioned 5.6.4.  
<a
href='https://www.kde.org/announcements/plasma-5.6.0.php'>Plasma 5.6</a>
was released in March with many feature refinements and new modules to complete the desktop experience.
");?>
</p>

<p>
<?php i18n("
This release adds a month's worth of new
translations and fixes from KDE's contributors.  The bugfixes are
typically small but important and include:
");?>
</p>

<ul>
<?php i18n("
<li>Make sure kcrash is initialized for discover. <a href='http://quickgit.kde.org/?p=discover.git&amp;a=commit&amp;h=63879411befc50bfd382d014ca2efa2cd63e0811'>Commit.</a> </li>
<li>Build Breeze Plymouth and Breeze Grub tars from correct branch</li>
<li>[digital-clock] Fix display of seconds with certain locales. <a href='http://quickgit.kde.org/?p=plasma-workspace.git&amp;a=commit&amp;h=a7a22de14c360fa5c975e0bae30fc22e4cd7cc43'>Commit.</a> Code review <a href='https://git.reviewboard.kde.org/r/127623'>#127623</a></li>
");?>
</ul>

<a href="plasma-5.6.3-5.6.4-changelog.php">
<?php i18n("Full Plasma 5.6.4 changelog");?></a>

<!-- // Boilerplate again -->

<h2><?php i18n("Live Images");?></h2>

<p><?php print i18n_var("
The easiest way to try it out is with a live image booted off a
USB disk. You can find a list of <a href='%1'>Live Images with Plasma 5</a> on the KDE Community Wiki.
", "https://community.kde.org/Plasma/LiveImages");?></p>

<h2><?php i18n("Package Downloads");?></h2>

<p><?php i18n("Distributions have created, or are in the process
of creating, packages listed on our wiki page.
");?></p>

<ul>
<li>
<?php print i18n_var("<a
href='https://community.kde.org/Plasma/Packages'>Package
download wiki page</a>"
, $release);?>
</li>
</ul>

<h2><?php i18n("Source Downloads");?></h2>

<p><?php i18n("You can install Plasma 5 directly from source. KDE's
community wiki has <a
href='http://community.kde.org/Frameworks/Building'>instructions to compile it</a>.
Note that Plasma 5 does not co-install with Plasma 4, you will need
to uninstall older versions or install into a separate prefix.
");?>
</p>

<ul>
<li>
<?php print i18n_var("
<a href='../info/%1.php'>Source Info Page</a>
", $release);?>
</li>
</ul>

<h2><?php i18n("Feedback");?></h2>

<?php print i18n_var("You can give us feedback and get updates on %1 or %2 or %3.", "<a href='https://www.facebook.com/kde'><img style='border: 0px; padding: 0px; margin: 0px' src='facebook.gif' width='32' height='32' /></a> <a href='https://www.facebook.com/kde'>Facebook</a>", "<a href='https://twitter.com/kdecommunity'><img style='border: 0px; padding: 0px; margin: 0px' src='twitter.png' width='32' height='32' /></a> <a href='https://twitter.com/kdecommunity'>Twitter</a>", "<a href='https://plus.google.com/105126786256705328374/posts'><img style='border: 0px; padding: 0px; margin: 0px' src='googleplus.png' width='30' height='30' /></a> <a href='https://plus.google.com/105126786256705328374/posts'>Google+</a>" );?>

<p>
<?php print i18n_var("Discuss Plasma 5 on the <a href='%1'>KDE Forums Plasma 5 board</a>.", "https://forum.kde.org/viewforum.php?f=289");?></a>
</p>

<p><?php print i18n_var("You can provide feedback direct to the developers via the <a href='%1'>#Plasma IRC channel</a>,
<a href='%2'>Plasma-devel mailing list</a> or report issues via
<a href='%3'>bugzilla</a>.  If you like what the
team is doing, please let them know!", "irc://#plasma@freenode.net", "https://mail.kde.org/mailman/listinfo/plasma-devel", "https://bugs.kde.org/enter_bug.cgi?product=plasmashell&format=guided");?></p>

<p><?php i18n("Your feedback is greatly appreciated.");?></p>

<h2>
  <?php i18n("Supporting KDE");?>
</h2>

<p align="justify">
 <?php i18n("KDE is a <a href='http://www.gnu.org/philosophy/free-sw.html'>Free Software</a> community that exists and grows only because of the help of many volunteers that donate their time and effort. KDE is always looking for new volunteers and contributions, whether it is help with coding, bug fixing or reporting, writing documentation, translations, promotion, money, etc. All contributions are gratefully appreciated and eagerly accepted. Please read through the <a href='/community/donations/'>Supporting KDE page</a> for further information or become a KDE e.V. supporting member through our <a href='https://relate.kde.org/civicrm/contribute/transact?id=5'>Join the Game</a> initiative. </p>");?>

<?php
  include($site_root . "/contact/about_kde.inc");
?>

<h2><?php i18n("Press Contacts");?></h2>

<?php
  include($site_root . "/contact/press_contacts.inc");
  include("footer.inc");
