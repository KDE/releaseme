<?php
  require_once('aether/config.php');
  
  $pageConfig = array_merge($pageConfig, [
    'title' => "KDE Community Home",
    'cdnCSSFiles' => ['/version/kde-org/plasma-desktop.css', '/version/kde-org/applications.css', '/version/kde-org/index.css'],
  ]);
  
  require_once('aether/header.php');
?>
<main id="home">
  <section class="section-blue" id="plasma">
    <div class="container">
      <div>
      <h1>Plasma</h1>
      <h2>The next generation desktop for Linux</h2>
      <div class="laptop-with-overlay d-inline-block">
        <img class="laptop img-fluid mb-3" src="/content/plasma-desktop/laptop.png" alt="empty laptop with an overlay">
        <div class="laptop-overlay">
          <img class="img-fluid mb-3" src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 3 2'%3E%3C/svg%3E" data-src="/content/home/kde-main.jpg" alt="Screenshot Plasma with Okular open" />
        </div>
      </div>
      </div>
      <div class="plasma-info">
        <a href="/distributions" class="learn-more button mb-3">Install on your computer</a>
        <a href="/plasma-desktop" class="learn-more mb-3">Discover Plasma</a>
        <a href="/hardware" class="learn-more mb-3">Buy a computer with Plasma</a>
      </div>
    </div>
  </section>

  <section id="kde-connect">
    <div class="container">
      <h1>KDE's Applications</h1>
      <h2>Powerful, multi-platform and for all</h2>
      <p>Use KDE software to surf the web, keep in touch with colleagues, friends and family, manage your files, enjoy music and videos; and get creative and productive at work. The KDE community develops and maintains more than <strong>200</strong> applications which run on any Linux desktop, and often other platforms too.</p>
      <p>
        <a class="learn-more mt-3" href="/applications">See all applications</a>
      </p>
      <div>
      <div class="row mb-5 mt-5 app" id="krita-showcaste">
        <div class="col-12 col-lg-5 app-description mt-4">
          <div>
            <a href="https://krita.org"><img src="https://kde.org/applications/icons/org.kde.krita.svg" alt="Krita logo" width="90" height="90"></a>
            <h3 class="mt-1"><a href="https://krita.org">Krita</a></h3>
            <p>Get creative and draw beautiful artwork with Krita. A professional grade painting application.</p>
          </div>
        </div>
        <a href="https://krita.org" class="col-12 col-lg-7"><img class="img-fluid" src="https://krita.org/wp-content/uploads/2019/08/krita-ui-40.png" alt="Krita screenshot" /></a>
      </div>
      <div class="row mt-5 app" id="kdenlive-showcaste">
        <div class="col-12 col-lg-5 app-description mt-4">
          <div class="w-100">
            <a href="https://kdenlive.org"><img src="/content/home/kdenlive.svg" alt="Kdenlive logo" width="90" height="90"></a><br />
            <h3 class="mt-1"><a href="https://kdenlive.org">Kdenlive</a></h3>
            <p>Kdenlive allows you to edit your videos and add special effects and transitions.</p>
          </div>
        </div>
        <a href="https://kdenlive.org" class="col-12 col-lg-7"><img class="img-fluid" src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 3 2'%3E%3C/svg%3E" data-src="https://kde.org/applications/thumbnails/org.kde.kdenlive/k1.png" /></a>
      </div>
      <div class="row mt-5 app" id="kontact-showcaste">
        <div class="col-12 col-lg-5 mt-4 app-description">
          <div class="w-100">
            <a href="https://kontact.kde.org.org"><img src="https://kde.org/applications/icons/org.kde.kontact.svg" alt="Kontact logo" width="90" height="90"></a>
            <h3 class="mt-1"><a href="https://kontact.kde.org.org">Kontact</a></h3>
            <p>Handle all your emails, calendars and contacts within a single window with Kontact.</p>
          </div>
        </div>
        <a href="https://kontact.kde.org.org" class="col-12 col-lg-7"><img class="img-fluid" src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 3 2'%3E%3C/svg%3E" data-src="https://kontact.kde.org/assets/img/kontact-korganizer.png" /></a>
      </div>
      <div class="row mb-5 app mt-5" id="kdevelop-showcaste">
        <div class="col-12 col-lg-5 mt-4 app-description">
          <div class="w-100">
            <a href="https://kdevelop.org"><img src="https://kde.org/applications/icons/org.kde.kdevelop.svg" alt="KDevelop logo" width="90" height="90"></a>
            <h3 class="mt-1"><a href="https://kdevelop.org">KDevelop</a></h3>
            <p>KDevelop is a cross-platform IDE for C, C++, Python, QML/JavaScript and PHP</p>
          </div>
        </div>
        <a href="https://kdevelop.org" class="col-12 col-lg-7"><img class="img-fluid" src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 3 2'%3E%3C/svg%3E" data-src="https://www.kdevelop.org/sites/www.kdevelop.org/files/inline-images/kdevelop5-breeze_2.png" /></a>
      </div>
      <div class="row app mt-5" id="gcompris-showcaste">
        <div class="col-12 col-lg-5 mt-4 app-description">
          <div class="w-100">
            <a href="https://gcompris.net"><img src="https://kde.org/applications/icons/org.kde.gcompris.svg" alt="GCompris logo" width="90" height="90"></a>
            <h3 class="mt-1"><a href="https://gcompris.net">GCompris</a></h3>
            <p>GCompris is a high quality educational software suite, including a large number of activities for children aged 2 to 10.</p>
          </div>
        </div>
        <a href="https://gcompris.net" class="col-12 col-lg-7"><img class="img-fluid" src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 3 2'%3E%3C/svg%3E" data-src="https://kde.org/applications/thumbnails/org.kde.gcompris/gcompris.png" /></a>
      </div>
      </div>
    </div>
  </section>
  
  <section class="section-blue">
    <div class="container">
      <h1>Hardware</h1>
      <h2>Buy a computer with Plasma preinstalled</h2>
      <div class="hardware-grid">
        <div class="pinebook">
          <a href="https://www.pine64.org/pinebook-pro/">
            <img src="/content/hardware/pinebook-pro.png" alt="Pinebook Pro"/>
          </a>
        </div>
        <div class="pinebook-desc">
          <h5><a href="https://www.pine64.org/pinebook-pro/">Pinebook Pro</a></h5>
          <p class="text-left">The Pinebook Pro is an affordable ARM powered laptop. It is modular and hackable in a way that only an Open Source project can be.</p>
        </div>
        <div class="slimbook">
          <a href="https://kde.slimbook.es/">
            <img src="/content/hardware/slimbook.png" alt="KDE Slimabook II"/>
          </a>
        </div>
        <div class="slimbook-desc">
          <h5><a href="https://kde.slimbook.es/">KDE Slimbook II</a></h5>
          <p class="text-left">The Slimbook is a shiny, sleek and good looking laptop that can do any task thanks to its powerful intel core-series processor.</p>
        </div>
        <div class="focus">
          <a href="https://kfocus.org/">
            <img src="/content/hardware/focus.png" alt="Kubuntu Focus"/>
          </a>
        </div>
        <div class="focus-desc">
          <h5><a href="https://kfocus.org/">Kubuntu Focus</a></h5>
          <p class="text-left">The Kubuntu Focus laptop is a high-powered, workflow-focused laptop which ships with Kubuntu installed.</p>
        </div>
      </div>
      <p>Other hardware manufacturers are selling computers with Plasma. <a href="/hardware">Learn more.</a></p>
    </div>
  </section>

  <section class="section-green">
    <div class="container my-4">
      <h1 class="mb-3">Announcements</h1>
      <ul class="list-unstyled">
                <!-- This comment is a marker for Latest Announcements, used by scripts -->
                <li>
                    <h2>KDE Releases Frameworks 5.69.0</h2>
                    <i>April 11, 2020</i><br />
                    <q>This release is part of a series of planned monthly releases
                    making improvements available to developers in a quick and predictable
                    manner. </q><br />
                    <a href="https://www.kde.org/announcements/kde-frameworks-5.69.0.php" class="learn-more">Read full announcement</a>
                </li>
                <li>
                    <h1>KDE Plasma 5.18.4 Released</h2>
                    <i>Tuesday, 31 March 2020</i><br />
                    <q>Today KDE releases a new release of KDE Plasma 5, versioned 5.18.4</q><br />
                    <a href="announcements/plasma-5.18.4" class="learn-more">Read full announcement</a>
                </li>
                <li>
                    <h2>March Apps Update Featuring Releases 19.12.3</h2>
                    <i>March 5, 2020</i><br />
                    <q>New releases from KDE in the last month.</q><br />
                    <a href="announcements/releases/2020-03-apps-update/" class="learn-more">Read full announcement</a>
                </li>
      </ul>

      <a href="announcements/" class="learn-more" style="font-weight: bold;">&#x1F4E2; View all announcements</a>
    </div>
  </section>

  <section>
    <div class="container">
      <h1 class="mb-3" id="community">Community</h1>
      <p>KDE is an international team cooperating on development and distribution of Free, Open Source Software for desktop and portable computing. Our community has developed a wide variety of applications for communication, work, education and entertainment. We have a strong focus on finding innovative solutions to old and new problems, creating a vibrant, open atmosphere for experimentation</p>
      <div class="text-center mb-3">
        <a href="/community/whatiskde" class="button ml-2 mr-2">Learn More</a>
        <a href="https://community.kde.org/Get_Involved" class="noblefir ml-2 mr-2">Get Involved</a>
      </div>
    </div>
    <div class="card-columns container-fluid">
      <figure class="text-center card">
        <picture class="img-fluid">
          <source srcset="/content/people/lakademy-2019.jpg 1x, /content/people/lakademy-2019x2.jpg 2x">
          <img src="/content/people/lakademy-2019.jpg" alt="LaKademy 2018 group photo" class="img-fluid">
        </picture>
        <figcaption class="card-body">
          <a href="https://lakademy.kde.org/">LaKademy 2018</a> - Salvador, Brazil
        </figcaption>
      </figure>
      <figure class="text-center card">
        <picture class="img-fluid">
           <source srcset="/content/people/conf-kde-in-2019.jpg 1x, /content/people/conf-kde-in-2019x2.jpg 2x">
           <img src="/content/people/conf-kde-in-2019.jpg" alt="Conf.KDE.in group photo" class="img-fluid">
        </picture>
        <figcaption class="card-body">
          <a href="https://conf.kde.in">conf.kde.in</a> - Dehli, India
        </figcaption>
      </figure>
      <figure class="text-center card">
        <picture class="img-fluid">
          <source srcset="/content/people/kde-connect.jpg 1x, /content/people/kde-connectx2.jpg 2x">
          <img src="/content/people/kde-connect.jpg" alt="KDE Connect Sprint" class="img-fluid">
        </picture>
        <figcaption class="card-body">
          <a href="https://dot.kde.org/2018/05/28/2018-kde-connect-development-sprint">KDE Connect Sprint</a> - Barcelona
        </figcaption>
      </figure>
      <figure class="text-center card">
        <img src="/content/people/plasma-sprint.jpg" alt="Plasma Sprint" class="img-fluid">
        <figcaption class="card-body">
          <a href="https://dot.kde.org/2018/05/14/plasma-sprint-berlin">Plasma Sprint</a> - Berlin
        </figcaption>
      </figure>
      <figure class="text-center card">
        <picture class="img-fluid">
          <source srcset="/content/people/kdenlive-sprint.jpg 1x, /content/people/kdenlive-sprintx2.jpg 2x">
          <img src="/content/people/kdenlive-sprint.jpg" alt="KDenlive Sprint group photo" class="img-fluid">
        </picture>
        <figcaption class="card-body">
          <a href="https://dot.kde.org/2018/05/12/kdenlive-sprint-movie">Kdenlive Sprint</a> - Paris, France
        </figcaption>
      </figure>
      <figure class="text-center card">
        <picture class="img-fluid">
          <source srcset="/content/people/GSoC.jpg 1x, /content/people/GSoCx2.jpg 2x">
          <img src="/content/people/GSoC.jpg" alt="KDE GSoC students group photo" class="img-fluid">
        </picture>
        <figcaption class="card-body">
          <a href="https://community.kde.org/GSoC">Google Summer of Code students</a>
        </figcaption>
      </figure>
      <figure class="text-center card">
        <picture class="w-100">
          <source srcset="/content/people/goal.jpg 1x, /content/people/goal.jpg 2x">
          <img src="/content/people/goal.jpg" alt="KDE goals" class="img-fluid w-100">
        </picture>
        <figcaption class="card-body">
          <a href="https://dot.kde.org/2019/09/07/kde-decides-three-new-challenges-wayland-consistency-and-apps">KDE Goals</a>
        </figcaption>
      </figure>
      <figure class="text-center card">
        <picture class="img-fluid">
          <source srcset="/content/people/kf6-sprint.jpg 1x, /content/people/kf6-sprintx2.jpg 2x">
          <img src="/content/people/kf6-sprint.jpg" alt="KF6 Sprint group photo" class="img-fluid w-100">
        </picture>
        <figcaption class="card-body">
          <a href="https://ervin.ipsquad.net/blog/2019/11/24/kf6-kickoff-sprint-wrap-up/">KF6 Sprint</a> - Berlin, Germany
        </figcaption>
      </figure>
      <figure class="text-center card">
        <picture class="img-fluid">
          <source srcset="/content/people/lakademy-2018.jpg 1x, /content/people/lakademy-2018x2.jpg 2x">
          <img src="/content/people/lakademy-2018.jpg" alt="LaKademy 2018 group photo" class="img-fluid w-100">
        </picture>
        <figcaption class="card-body">
          <a href="https://dot.kde.org/2018/10/25/lakademy-2018-celebrates-22-years-kde">Lakademy</a> - Florianopolis, Brazil
        </figcaption>
      </figure>
    </div>
  </section>
</main>

<?php require('aether/footer.php'); ?>
