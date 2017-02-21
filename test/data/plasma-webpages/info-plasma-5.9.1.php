<?php
	require('../aether/config.php');

	$pageConfig = array_merge($pageConfig, [
		'title' => "KDE Plasma 5.9.1, Bugfix Release",
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
table {
	margin: 0px auto;
	background-color: #eff1f1;
}
table tr:nth-child(odd) {
	background-color: #fafafa;
}
table td {
	padding: 4px 10px;
}
</style>

<main class="releaseAnnouncment container">

    <h1>NOT OUT YET</h1>

	<h1 class="announce-title">KDE Plasma 5.9.1, Feature Release</h1>

<p>This is a Feature release of KDE Plasma, featuring Plasma Desktop and
other essential software for your computer.  Details in the <a
href="../announcements/plasma-<?php echo $release; ?>.php">Plasma <?php echo $release; ?> announcement</a>.</p>

<h2>Security Issues</h2>

<p>Please report possible problems to <a
href="m&#x61;i&#00108;&#x74;o:&#115;ec&#117;&#x72;&#00105;&#x74;&#121;&#x40;kde.&#00111;&#x72;g">&#x73;&#101;&#x63;u&#114;i&#x74;y&#x40;kd&#101;.&#x6f;&#00114;&#103;</a>.
Security issues are listed on the <a
href="http://kde.org/info/security/">KDE Security Advisories</a> page.</p>

<h2><a name="bugs">Bugs</a></h2>

<p><a href="https://community.kde.org/Plasma/5.9_Errata">5.9 Errata wiki page</a> lists the most important known problems.</p>

<p>Please check the <a href="http://bugs.kde.org/">bug database</a>
before filing any bug reports. Also check for possible updates on this page
that might describe or fix your problem.</p>

<h2>Install Packages</h2>

<p> The easiest way to install and use Plasma 5 is to install
 pre-built packages.  For details of Linux distributions which do so
 see the <a href="https://community.kde.org/Plasma/Packages">Plasma
 Binary Packages wiki page</a>.</p>

<h2>Source Install and Use</h2>

<p>You can compile Plasma yourself if you are a software developer.  See the
 <a href="http://community.kde.org/Plasma/Building">Build instructions</a>
 on our developer wiki.
</p>

<h2><a name="source">Download Source Code</a></h2>
<p>
  The complete source code for Plasma <?php echo $version; ?> is available for download from <a href="http://download.kde.org/stable/plasma/<?php echo $version; ?>">download.kde.org</a>.
</p>

<p>GPG signatures are available alongside the source code for
verification. They are signed by release manager <a
href="https://sks-keyservers.net/pks/lookup?op=vindex&search=0xEC94D18F7F05997E">Jonathan Riddell with 0xEC94D18F7F05997E</a>.  Git tags are also signed by the
same key.</p>

<?php
	include "source-plasma-$release.inc";
?>
</main>
<?php
	require('../aether/footer.php');
