<?php
	require('../aether/config.php');

	$pageConfig = array_merge($pageConfig, [
		'title' => "KDE Plasma 5.9.1, Feature Release for January",
		'cssFile' => '/content/home/portal.css'
	]);
	
	require('../aether/header.php');
	$site_root = "../";
	$release = "5.9.1";
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
</style>

<main class="releaseAnnouncment container">

	<h1 class="announce-title"><a href="/announcements/">Release Announcements</a>Plasma 5.9.1</h1>

	<figure class="videoBlock">
		<iframe width="560" height="315" src="https://www.youtube.com/embed/lm0sqqVcotA?rel=0" allowfullscreen></iframe>
	</figure>
	
	
	<figure class="topImage">
		<a href="plasma-5.9/plasma-5.9.png">
			<img src="plasma-5.9/plasma-5.9-wee.png" width="600" height="338" alt="Plasma 5.9" />
		</a>
		<figcaption>KDE Plasma 5.9</figcaption>
	</figure>

	<p>
		Tuesday, 14 February 2017.
		Today KDE releases a Feature update to KDE Plasma 5, versioned 5.9.1.
		<a href='https://www.kde.org/announcements/plasma-5.9.0.php'>Plasma 5.9</a>
		was released in January with many feature refinements and new modules to complete the desktop experience.
	</p>

	<p>
		This release adds a a month's worth of new
		translations and fixes from KDE's contributors.  The bugfixes are
		typically small but important and include:
	</p>

	<ul>
		<li>Fix i18n extraction: xgettext doesn't recognize single quotes. <a href='https://commits.kde.org/plasma-desktop/8c174b9c1e0b1b1be141eb9280ca260886f0e2cb'>Commit.</a></li>
		<li>Set wallpaper type in SDDM config. <a href='https://commits.kde.org/sddm-kcm/19e83b28161783d570bde2ced692a8b5f2236693'>Commit.</a> Fixes bug <a href='https://bugs.kde.org/370521'>#370521</a></li>
	</ul>

	<a href="plasma-5.9.0-5.9.1-changelog.php">Full Plasma 5.9.1 changelog</a>

	<!-- // Boilerplate again -->
	<section class="row get-it">
		<article class="col-md">
			<h2>Live Images</h2>
			<p>
				The easiest way to try it out is with a live image booted off a
				USB disk. Docker images also provide a quick and easy way to test Plasma.
			</p>
			<a href='https://community.kde.org/Plasma/Live_Images' class="learn-more">Download live images with Plasma 5</a>
			<a href='https://community.kde.org/Plasma/Docker_Images' class="learn-more">Download Docker images with Plasma 5</a>
		</article>
			
		<article class="col-md">
			<h2>Package Downloads</h2>
			<p>
				Distributions have created, or are in the process
				of creating, packages listed on our wiki page.
			</p>
			<a href='https://community.kde.org/Plasma/Packages' class="learn-more">Package download wiki page</a>
		</article>
			
		<article class="col-md">
			<h2>Source Downloads</h2>
			<p>
				You can install Plasma 5 directly from source.
			</p>
			<a href='http://community.kde.org/Frameworks/Building'>Community instructions to compile it</a>
			<a href='../info/plasma-5.9.1.php' class='learn-more'>Source Info Page</a>
		</article>
	</section>

	<section class="give-feedback">
		<h2>Feedback</h2>

		<p>
			You can give us feedback and get updates on
			<a href='https://www.facebook.com/kde'><img src='https://www.kde.org/announcements/facebook.gif' /></a> <a href='https://www.facebook.com/kde'>Facebook</a>
			or <a href='https://twitter.com/kdecommunity'><img src='https://www.kde.org/announcements/twitter.png' /></a> <a href='https://twitter.com/kdecommunity'>Twitter</a>
			or <a href='https://plus.google.com/105126786256705328374/posts'><img src='https://www.kde.org/announcements/googleplus.png' /></a> <a href='https://plus.google.com/105126786256705328374/posts'>Google+</a>.
		</p>
		<p>
		Discuss Plasma 5 on the <a href='https://forum.kde.org/viewforum.php?f=289'>KDE Forums Plasma 5 board</a>.
		</p>

		<p>You can provide feedback direct to the developers via the <a href='irc://#plasma@freenode.net'>#Plasma IRC channel</a>,
		<a href='https://mail.kde.org/mailman/listinfo/plasma-devel'>Plasma-devel mailing list</a> or report issues via
		<a href='https://bugs.kde.org/enter_bug.cgi?product=plasmashell&amp;format=guided'>bugzilla</a>.  If you like what the
		team is doing, please let them know!

		<p>Your feedback is greatly appreciated.</p>
	</section>

	<h2>
		Supporting KDE
	</h2>

	<p align="justify">

	KDE is a <a href='http://www.gnu.org/philosophy/free-sw.html'>Free Software</a> community that exists and grows only because of the help of many volunteers that donate their time and effort. KDE is always looking for new volunteers and contributions, whether it is help with coding, bug fixing or reporting, writing documentation, translations, promotion, money, etc. All contributions are gratefully appreciated and eagerly accepted. Please read through the <a href='/community/donations/'>Supporting KDE page</a> for further information or become a KDE e.V. supporting member through our <a href='https://relate.kde.org/civicrm/contribute/transact?id=5'>Join the Game</a> initiative. </p>
<?php
  include($site_root . "/contact/about_kde.inc");
?>
</main>
<?php
	require('../aether/footer.php');
