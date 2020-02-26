<?php
	require('../aether/config.php');

	$pageConfig = array_merge($pageConfig, [
		'title' => "Plasma VERSION Complete Changelog",
		'cssFile' => 'content/home/portal.css'
	]);

	require('../aether/header.php');
	$site_root = "../";
	$release = "VERSION";
?>

<style>
main {
	padding-top: 20px;
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

<p><a href="plasma-<?php print $release; ?>">Plasma <?php print $release; ?></a> Complete Changelog</p>
