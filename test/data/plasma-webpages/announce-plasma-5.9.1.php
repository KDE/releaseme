<?php
	include_once ("functions.inc");
	$translation_file = "www";
	require('../aether/config.php');

	$pageConfig = array_merge($pageConfig, [
		'title' => "KDE Plasma 5.9.1, Bugfix Release for January",
		'cssFile' => '/content/home/portal.css'
	]);

	require('../aether/header.php');
	$site_root = "../";
	$release = 'plasma-5.9.1'; // for i18n
	$version = "5.9.1";
?>

<style>
main {
	padding-top: 20px;
	}

.videoBlock {
	background-color: #334545;
	border-radius: 2px;
	text-align: center;
}

.videoBlock iframe {
	margin: 0px auto;
	display: block;
	padding: 0px;
	border: 0;
}

.topImage {
	text-align: center
}

.releaseAnnouncment h1 a {
	color: #6f8181 !important;
}

.releaseAnnouncment h1 a:after {
	color: #6f8181;
	content: ">";
	font-family: "glyph";
	font-size: 60%;
	vertical-align: middle;
	margin: 0px 5px;
}

.releaseAnnouncment img {
	border: 0px;
}

.get-it {
	border-top: solid 1px #eff1f1;
	border-bottom: solid 1px #eff1f1;
	padding: 10px 0px 20px;
	margin: 10px 0px;
}

.releaseAnnouncment ul {
	list-style-type: none;
	padding-left: 40px;
}
.releaseAnnouncment ul li {
	position: relative;
}

.releaseAnnouncment ul li:before {
	content: ">";
	font-family: "glyph";
	font-size: 60%;
	position: absolute;
	top: .8ex;
	left: -20px;
	font-weight: bold;
	color: #3bb566;
}

.give-feedback img {
	padding: 0px; 
	margin: 0px;
	height: 2ex;
	width: auto;
	vertical-align: middle;
}

figure {
    position: relative;
    z-index: 2;
    font-size: smaller;
    text-shadow: 2px 2px 5px light-grey;
}

</style>

<main class="releaseAnnouncment container">

	<h1 class="announce-title"><a href="/announcements/"><?php i18n("Release Announcements")?></a><?php print i18n_var("Plasma %1", $version)?></h1>

	<?php include "./announce-i18n-bar.inc"; ?>

	<figure class="videoBlock">
		<iframe width="560" height="315" src="https://www.youtube.com/embed/lm0sqqVcotA?rel=0" allowfullscreen='true'></iframe>
	</figure>
	
	
	<figure class="topImage">
		<a href="plasma-5.9/plasma-5.9.png">
			<img src="plasma-5.9/plasma-5.9-wee.png" width="600" height="338" alt="Plasma 5.9" />
		</a>
		<figcaption><?php print i18n_var("KDE Plasma %1", "5.9")?></figcaption>
	</figure>

	<p>
		<?php i18n("Tuesday, 14 February 2017.")?>
		<?php print i18n_var("Today KDE releases a %1 update to KDE Plasma 5, versioned %2", "Bugfix", "5.9.1");?>.
		<?php print i18n_var("<a href='https://www.kde.org/announcements/plasma-%1.0.php'>Plasma %1</a>
		was released in %2 with many feature refinements and new modules to complete the desktop experience.", "5.9", "January");?>
	</p>

	<p>
<?php		print i18n_var("This release adds a %1 worth of new translations and fixes from KDE's contributors.  The bugfixes are typically small but important and include:", "a month's");?>
	</p>

	<ul>
		<li><?php i18n("FIXME")?></li>
	</ul>

	<a href="plasma-5.9.0-5.9.1-changelog.php"><?php print i18n_var("Full Plasma %1 changelog", "5.9.1"); ?></a>

	<!-- // Boilerplate again -->
	<section class="row get-it">
		<article class="col-md">
			<h2><?php i18n("Live Images");?></h2>
			<p>
				<?php i18n("The easiest way to try it out is with a live image booted off a USB disk. Docker images also provide a quick and easy way to test Plasma.");?>
			</p>
			<a href='https://community.kde.org/Plasma/Live_Images' class="learn-more"><?php i18n("Download live images with Plasma 5");?></a>
			<a href='https://community.kde.org/Plasma/Docker_Images' class="learn-more"><?php i18n("Download Docker images with Plasma 5");?></a>
		</article>

		<article class="col-md">
			<h2><?php i18n("Package Downloads");?></h2>
			<p>
				<?php i18n("Distributions have created, or are in the process of creating, packages listed on our wiki page.");?>
			</p>
			<a href='https://community.kde.org/Plasma/Packages' class="learn-more"><?php i18n("Package download wiki page");?></a>
		</article>

		<article class="col-md">
			<h2><?php i18n("Source Downloads");?></h2>
			<p>
				<?php i18n("You can install Plasma 5 directly from source.");?>
			</p>
			<a href='http://community.kde.org/Frameworks/Building'><?php i18n("Community instructions to compile it");?></a>
			<a href='../info/plasma-5.9.1.php' class='learn-more'><?php i18n("Source Info Page");?></a>
		</article>
	</section>

	<section class="give-feedback">
		<h2><?php i18n("Feedback");?></h2>

		<p>
			<?php print i18n_var("You can give us feedback and get updates on <a href='%1'><img src='%2' /></a> <a href='%3'>Facebook</a>
			or <a href='%4'><img src='%5' /></a> <a href='%6'>Twitter</a>
			or <a href='%7'><img src='%8' /></a> <a href='%9'>Google+</a>.", "https://www.facebook.com/kde", "https://www.kde.org/announcements/facebook.gif", "https://www.facebook.com/kde", "https://twitter.com/kdecommunity", "https://www.kde.org/announcements/twitter.png", "https://twitter.com/kdecommunity", "https://plus.google.com/105126786256705328374/posts", "https://www.kde.org/announcements/googleplus.png", "https://plus.google.com/105126786256705328374/posts"); ?>
		</p>
		<p>
			<?php print i18n_var("Discuss Plasma 5 on the <a href='%1'>KDE Forums Plasma 5 board</a>.", "https://forum.kde.org/viewforum.php?f=289");?>
		</p>

		<p><?php print i18n_var("You can provide feedback direct to the developers via the <a href='%1'>#Plasma IRC channel</a>, <a href='%2'>Plasma-devel mailing list</a> or report issues via <a href='%3'>bugzilla</a>. If you like what the team is doing, please let them know!", "irc://#plasma@freenode.net", "https://mail.kde.org/mailman/listinfo/plasma-devel", "https://bugs.kde.org/enter_bug.cgi?product=plasmashell&amp;format=guided"); ?>

		<p><?php i18n("Your feedback is greatly appreciated.");?></p>
	</section>

	<h2>
		<?php i18n("Supporting KDE");?>
	</h2>

	<p align="justify">
		<?php print i18n_var("KDE is a <a href='%1'>Free Software</a> community that exists and grows only because of the help of many volunteers that donate their time and effort. KDE is always looking for new volunteers and contributions, whether it is help with coding, bug fixing or reporting, writing documentation, translations, promotion, money, etc. All contributions are gratefully appreciated and eagerly accepted. Please read through the <a href='%2'>Supporting KDE page</a> for further information or become a KDE e.V. supporting member through our <a href='%3'>Join the Game</a> initiative.", "http://www.gnu.org/philosophy/free-sw.html", "/community/donations/", "https://relate.kde.org/civicrm/contribute/transact?id=5"); ?>
	</p>

<?php
  include($site_root . "/contact/about_kde.inc");
?>

<h2><?php i18n("Press Contacts");?></h2>

<?php
  include($site_root . "/contact/press_contacts.inc");
?>

</main>
<?php
  require('../aether/footer.php');
