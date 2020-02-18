<?php
    require('aether/config.php');

    $pageConfig = array_merge($pageConfig, [
        'title' => "KDE Community Home",
        'cssFile' => 'content/home/portal.css?ver=1.1'
    ]);

    require('aether/header.php');

    if (@include_once("libs/class_db.php")) {
        define("FRONTPAGE_LIVE_FEED", true);
    }

    if (defined("FRONTPAGE_LIVE_FEED")) {
        require_once('users_conf.php');
        require_once('aetherlibs/functions.php');
        require_once("aetherlibs/feeds.php");
    }

?>


    <section id="headerCarousel" class="heroDisplay carousel slide overlay" data-ride="carousel">
        <div class="carousel-inner" role="listbox" style="background-color: #333;">

            <article id="slide-kirigami" class="carousel-item light-text active" style="position: relative">
                <div style="position: relative; text-align: center; width: 100%; top: 80px;">
                    <h1 style="margin-top: -4ex;">Create Convergent Apps with Kirigami</h1>
                    <a  href="products/kirigami/"  target="_blank" class="learn-more">Learn More</a>
                </div>
            </article>

            <article id="slide-kde-laptop" class="carousel-item dark-text" style="position: relative">
                <div style="position: relative; text-align: center; width: 100%; top: 50%; margin-top: -40px;">
                    <h1 style="margin-top: -4ex;">Announcing the KDE Slimbook</h1>
                    <a  href="http://kde.slimbook.es/"  target="_blank" class="learn-more">Learn More</a>
                </div>
            </article>

            <article id="slide-plasma-5-12" class="carousel-item light-text">
                <h1>Plasma 5.12 LTS</h1>
                <div class="carousel-caption">
                    <p>Our desktop, featuring long-term support so you can compute without worries.</p>
                    <a href="announcements/plasma-5.12.0.php" class="learn-more">Learn More</a>
                </div>
            </article>

            <article id="slide-the-game" class="carousel-item light-text">
                <div style="text-align: center; width: 100%;">
                <h1>Join the Game</h1>
                    <p>Invest in freedom; become a personal member or enroll your company as a contributing member or patron.</p>
                    <a href="https://relate.kde.org/civicrm/contribute/transact?reset=1&id=5" class="learn-more">Learn More</a>
                </div>
            </article>

        </div>


        <a class="carousel-control-prev" href="#headerCarousel" role="button" data-slide="prev" onclick="return false;">
            <span class="sr-only">Previous</span>
        </a>
        <a class="carousel-control-next" href="#headerCarousel" role="button" data-slide="next" onclick="return false;">
            <span class="sr-only">Next</span>
        </a>

        <ol class="carousel-indicators">
            <li data-target="#headerCarousel" data-slide-to="0" class="active"></li>
            <li data-target="#headerCarousel" data-slide-to="1"></li>
            <li data-target="#headerCarousel" data-slide-to="2"></li>
            <li data-target="#headerCarousel" data-slide-to="3"></li>
        </ol>
    </section>


        <aside id="kWelcome" class="container">
            The KDE® Community is a free software community dedicated to creating an open and user-friendly computing experience, offering an advanced graphical desktop, a wide variety of applications for communication, work, education and entertainment and a platform to easily build new applications upon. We have a strong focus on finding innovative solutions to old and new problems, creating a vibrant atmosphere open for experimentation.
        </aside>

    <main class="container">
        <div class="row">
            <section id="announcement-feed" class="col-md">
            <h2 style="margin-bottom: 20px;">Announcements</h2>
                <ul>
                <!-- This comment is a marker for Latest Announcements, used by scripts -->
                    <li>
                        <h1>KDE Releases Frameworks 5.51.0 <i>October 15, 2018</i></h1>
                        <q>This release is part of a series of planned monthly releases
                        making improvements available to developers in a quick and predictable
                        manner. </q>
                        <a href="https://www.kde.org/announcements/kde-frameworks-5.51.0.php" class="learn-more">Read full announcement</a>
                    </li>
                    <li>
                        <h1>KDE Plasma 5.10.0 Released <i>November 15, 2014</i></h1>
                        <q>Today KDE releases a new release of KDE Plasma 5, versioned 5.10.0</q>
                        <a href="announcements/plasma-5.10.0.php" class="learn-more">Read full announcement</a>
                    </li>
                    <li>
                        <h1>KDE Ships KDE Applications 18.08.2 <i>October 11, 2018</i></h1>
                        <q>Today KDE released the new versions of KDE Applications.</q>
                        <a href="announcements/announce-applications-18.08.2.php" class="learn-more">Read full announcement</a>
                    </li>
                     <li>
                        <h1>KDE Plasma 5.12.7 LTS Released <i>September 25, 2018</i></h1>
                        <q>Today KDE releases a new Long Term Support release of KDE Plasma 5, versioned 5.12.7.</q>
                        <a href="announcements/plasma-5.12.7.php" class="learn-more">Read full announcement</a>
                    </li>
                </ul>

                <a href="announcements/" class="learn-more" style="font-weight: bold;">View all announcements</a>
            </section>

            <?php if (defined("FRONTPAGE_LIVE_FEED")): ?>
            <section id="homeFeedList" class="col-md">
            <h2 style="margin-bottom: 20px;">News</h2>
                <ul style="list-style-type: none; padding: 0px; margin: 0px;">
                <?php

                $items = Feeds::news(20);
                //$items = array_merge($items, Feeds::blog(8));

                svsort($items, 'timestamp');

                foreach ($items as $i) {
                    $i['url']   = htmlspecialchars($i['url']);
                    $i['title'] = htmlspecialchars($i['title']);
                    $i['user']  = htmlspecialchars(
                        isset($kde_contributors[$i['user']]) && isset($kde_contributors[$i['user']]['name']) ?
                            $kde_contributors[$i['user']]['name'] :
                            $i['user']
                        );

                    echo '<li><a href="'.$i['url'].'" class="learn-more">'.$i['title'].'</a></li>';
                }

                ?>
                </ul>

                <a href="https://dot.kde.org/" class="learn-more" style="font-weight: bold;">Read more news</a>
            </section>
            <?php endif;  ?>
        </div>
    </main>

<?php

    require('aether/footer.php');

?>
