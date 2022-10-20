# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2015-2021 Harald Sitter <sitter@kde.org>

require 'fileutils'

require_relative 'lib/testme'
require_relative '../lib/releaseme/l10n.rb'
require_relative '../lib/releaseme/l10n_statistics.rb'
require_relative '../lib/releaseme/documentation.rb'
require_relative '../lib/releaseme/tmpdir'

# FIXME: test stable

class TestL10n < Testme
  # Initialize a persistent reference repo. This repo will get copied for each
  # test to start from a pristine state. svn is fairly expensive so creating
  # new repos when the content doesn't change is costing multiple seconds!
  REFERENCE_TMPDIR, REFERENCE_REPO_PATH = begin
    tmpdir = ReleaseMe.mktmpdir(name) # cleaned via after_run hook
    repo_data_dir = data('l10nrepo/')

    svn_template_dir = "#{tmpdir}/tmp_l10n_repo"

    assert_run('svnadmin', 'create', svn_template_dir)
    raise unless File.exist?(svn_template_dir)

    ReleaseMe.mktmpdir(name) do |checkout_dir|
      checkout_dir = File.join(checkout_dir, "checkout")
      assert_run('svn', 'co', "file://#{svn_template_dir}", checkout_dir)
      FileUtils.cp_r("#{repo_data_dir}/trunk", checkout_dir)
      FileUtils.cp_r("#{repo_data_dir}/branches", checkout_dir)
      assert_run('svn', 'add', '--force', '.', chdir: checkout_dir)
      assert_run('svn', 'ci', '-m', 'yolo', chdir: checkout_dir)
    end

    [tmpdir, svn_template_dir]
  end

  Minitest.after_run do
    FileUtils.rm_rf(REFERENCE_TMPDIR)
  end

  def setup
    @i18n_path = 'amarok'
    @trunk_url = 'trunk/l10n-kf5/'
    @stable_url = 'branches/stable/l10n-kf5'

    @dir = 'tmp_l10n'
    @svn_template_dir = 'tmp_l10n_repo'
    FileUtils.cp_r(REFERENCE_REPO_PATH, @svn_template_dir)
    assert_path_exist(@svn_template_dir)

    ReleaseMe::L10n.languages = nil
  end

  def create_l10n(name = 'amarok', i18n_path = @i18n_path,
                  origin: ReleaseMe::L10n::TRUNK)
    l = ReleaseMe::L10n.new(origin, name, i18n_path)
    l.target = "#{@dir}/l10n"
    l
  end

  def assert_no_dotsvn(dir)
    svns = Dir.glob("#{dir}/**/.svn")
    assert_empty(svns, "There should be no lingering .svn dirs:\n  #{svns}")
  end

  def test_get_po
    # For visual string consinstency we actually interpolate pointlessly below.
    # rubocop:disable Style/UnneededInterpolation

    l = create_l10n
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    l.get(@dir)
    assert_path_exist("#{@dir}")
    assert_path_exist("#{@dir}/CMakeLists.txt")
    refute_path_exist("#{@dir}/l10n") # temp dir must not be there
    assert_path_exist("#{@dir}/po")
    assert_path_exist("#{@dir}/po/de/amarok.po")
    refute_path_exist("#{@dir}/poqm") # qt translation dir must not be there

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-pot'), @dir)
    l.get(@dir)
    assert_path_exist("#{@dir}")
    assert_path_exist("#{@dir}/CMakeLists.txt")
    refute_path_exist("#{@dir}/l10n") # temp dir must not be there
    assert_path_exist("#{@dir}/po")
    assert_path_exist("#{@dir}/po/de/amarok.po")
    assert_path_exist("#{@dir}/po/de/amarokcollectionscanner.po")
  end

  def test_get_po_elsewhere
    l = create_l10n
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    @elsewhere = "#{Dir.pwd}/elsewhere_tmp_l10n"

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    l.get(@dir, @elsewhere, edit_cmake: false)
    assert_path_exist("#{@elsewhere}/de/amarok.po")
  end

  def test_get_po_absolute_srcdir
    # Make sure we can pass an absolute dir as srcdir param.
    l = create_l10n
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    l.get(File.absolute_path(@dir))
    assert_path_exist("#{@dir}/po/de/amarok.po")
  end

  def test_get_po_edit_cmake
    l = create_l10n
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    l.get(@dir, edit_cmake: true)

    assert_path_exist("#{@dir}/CMakeLists.txt")
    assert_includes(File.read("#{@dir}/CMakeLists.txt"), 'ki18n_install(po)')
  end

  def test_get_po_no_edit_cmake
    l = create_l10n
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    l.get(@dir, edit_cmake: false)
    assert_path_exist("#{@dir}/CMakeLists.txt")
    refute_includes(File.read("#{@dir}/CMakeLists.txt"), 'ki18n_install(po)')
  end

  def test_statistics
    l = create_l10n
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-pot'), @dir)
    l.get(@dir)

    statistics = ReleaseMe::L10nStatistics.new(["#{@dir}/po"])
    de = statistics.languages.find { |x| x.name == 'de' }
    assert(de)
    assert_equal(de.all, 4)
    assert_equal(de.shown, 3)
    assert_equal(de.notshown, 1)
    assert_equal(de.percent_translated, 75.0)
    fr = statistics.languages.find { |x| x.name == 'fr' }
    assert(fr)
    assert_equal(fr.all, 4)
    assert_equal(fr.shown, 3)
    assert_equal(fr.notshown, 1)
    assert_equal(fr.fuzzy, 1)
    assert_equal(fr.percent_translated, 75.0)

    # Tuck this on to the test, we only care if the printer implodes.
    # Output is not aaaaallll that important and fairly hard to validate
    # without golden-references which are of course a bit shitty to manage.
    printer = ReleaseMe::L10nStatisticsHTMLPrinter.new(statistics, '123')
    out = '123.l10n.html'
    printer.write(out)
    assert_path_exist(out)
    refute(File.size(out) <= 0)

    # Bring up coverage for failure case
    fake_stat = mock('stat')
    fake_stat.stubs(:percent_translated).returns(-1)
    assert_equal('', printer.stat_color(fake_stat))
  end

  def test_space_and_declared_multi_pot
    l = create_l10n
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('space-and-declared-multi-pot'), @dir)
    l.get(@dir)
    assert_path_exist("#{@dir}/po/de/amarok.po")
    assert_path_exist("#{@dir}/po/de/amarokcollectionscanner.po")
  end

  def test_diff_output_some_not_found_all_not_found
    # When no translations were found we expect different output versus when
    # only some were not found.

    l = create_l10n
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-pot'), @dir)
    l.get(@dir)

    ENV.delete('RELEASEME_SHUTUP') # Reset by testme setup

    some_missing_stdout = StringIO.open do |io|
      $stdout = io
      l.instance_variable_set(:@__logger, nil) # Reset
      l.send(:print_missing_languages, [l.languages.pop])
      io.string.strip
    end

    all_missing_stdout = StringIO.open do |io|
      $stdout = io
      l.instance_variable_set(:@__logger, nil) # Reset
      l.send(:print_missing_languages, l.languages)
      io.string.strip
    end
    $stdout = STDOUT

    refute_empty(some_missing_stdout)
    refute_empty(all_missing_stdout)
    refute_equal(some_missing_stdout, all_missing_stdout)
  ensure
    $stdout = STDOUT
  end

  def test_script
    # https://techbase.kde.org/Localization/Concepts/Transcript

    l = create_l10n('ki18n', 'ki18n')
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-pot-script'), @dir)
    l.get(@dir)

    assert_path_exist("#{@dir}/po/sr/scripts")
    assert_path_exist("#{@dir}/po/sr/scripts/ki18n5")
    assert_path_exist("#{@dir}/po/sr/scripts/libplasma5")
    refute_path_exist("#{@dir}/po/sr/scripts/proto")

    assert_path_exist("#{@dir}/po/sr/scripts/ki18n5/ki18n5.js")
    assert_path_exist("#{@dir}/po/sr/scripts/ki18n5/trapnakron.pmap")

    assert_path_exist("#{@dir}/po/sr/scripts/libplasma5/libplasma5.js")
    assert_path_exist("#{@dir}/po/sr/scripts/libplasma5/plasmoid.js")

    assert_no_dotsvn("#{@dir}/po")
  end

  def test_releaseme_dir
    # This is a bit of a silly test. It is meant as an additional safeguard
    # against breaking relative path resolution. RELEASEME_DIR is meant
    # to be resolved to the main releaseme directory. The idea here is that
    # it's less likely both the test AND the lib get moved, so we'd get a
    # failing teset if any of the two move.
    # If you have come here because you moved the lib and get a failure:
    #   Make sure RELEASEME_DIR still resolves to the main releasme dir!
    # If you have come here because you moved the test and get a failure:
    #   Simply adjust the assertion to match reality.
    assert_equal(File.absolute_path(__dir__),
                 ReleaseMe::L10n::RELEASEME_TEST_DIR)
  end

  def test_data
    # https://techbase.kde.org/Localization/Concepts/Non_Text_Resources

    # Data assets actually have no identifying quality, translators are expected
    # to manually pick them out of the source VCS and put them into their l10n
    # tree without breaking anything. As such we need no source tree for the
    # test at all.

    l = create_l10n('ktuberling', 'ktuberling')
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    Dir.mkdir(@dir)
    File.write("#{@dir}/CMakeLists.txt", '')
    l.get(@dir)

    assert_path_exist("#{@dir}/po")
    assert_path_exist("#{@dir}/po/CMakeLists.txt")

    assert_path_exist("#{@dir}/po/de/data/ktuberling/CMakeLists.txt")
    assert_path_exist("#{@dir}/po/de/data/ktuberling/foo.fake.ogg")
    assert_path_exist("#{@dir}/po/de/data/ktuberling/bar.fake.ogg")

    assert_path_exist("#{@dir}/po/sr/data/ktuberling/CMakeLists.txt")
    assert_path_exist("#{@dir}/po/sr/data/ktuberling/foo.fake.ogg")
    assert_path_exist("#{@dir}/po/sr/data/ktuberling/bar.fake.ogg")

    # SR is a special snow flake, it needs cmake modules, the other 100
    # languages magically don't.
    # For testing reasons there's also one in our de directory to make sure
    # things wouldn't break with >1.
    assert_path_exist("#{@dir}/po/cmake_modules/deDataMacros.cmake")
    assert_path_exist("#{@dir}/po/cmake_modules/srDataMacros.cmake")

    # Make sure the CMakeLists properly adds our asset dir.
    assert(File.read("#{@dir}/po/CMakeLists.txt").include?('add_subdirectory(de/data/ktuberling)'))
    assert(File.read("#{@dir}/CMakeLists.txt").include?('ecm_optional_add_subdirectory(po)'))

    assert_no_dotsvn("#{@dir}/po")
  end

  def test_multi_pot_kde4
    # In KDE4 you could have foo_qt.po to mean anything. In KF5 based code this
    # explicitly means that this is a qt translation compiled to qm.
    # We'll assert that KDE4 origins are treated as previously expected, the new
    # behavior is checked elsewhere.

    l = create_l10n(origin: ReleaseMe::Origin::TRUNK_KDE4)
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-pot-kde4'), @dir)
    l.get(@dir)

    assert_path_exist("#{@dir}")
    assert_path_exist("#{@dir}/CMakeLists.txt")
    refute_path_exist("#{@dir}/l10n") # temp dir must not be there
    assert_path_exist("#{@dir}/po")
    assert_path_exist("#{@dir}/po/de/amarok.po")
    assert(File.exist?("#{@dir}/po/de/amarokcollectionscanner_qt.po"))

    refute(File.read("#{@dir}/CMakeLists.txt").include?('ecm_install_po_files_as_qm'))
  end

  def test_poqm
    # Qt strings get put into a foo_qt.po, they are meant to get installed via
    # ecm_install_po_files_as_qm from ECM.

    l = create_l10n('step', 'step')
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-pot-qt'), @dir)
    l.get(@dir)

    assert_path_exist("#{@dir}/poqm")
    assert_path_exist("#{@dir}/po/de/step.po")
    assert_path_exist("#{@dir}/poqm/de/step_qt.po")

    assert(File.read("#{@dir}/CMakeLists.txt").include?('ki18n_install(po)'))
    assert(File.read("#{@dir}/CMakeLists.txt").include?('ecm_install_po_files_as_qm(poqm)'))
  end

  def test_drop_worthless_po
    # When a translations has 0 strings translated there is no point in shipping
    # it, we'll drop it (including data and assets because we can't qualify
    # them, so we'll use lack of UI translations as indication for poor quality
    # everywhere).

    l = create_l10n('solid', 'solid')
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-pot-qt-frameworks'), @dir)
    l.get(@dir)

    assert_equal(%w[sr], l.zero_percent_dropped)

    assert_path_exist("#{@dir}/poqm")
    refute_path_exist("#{@dir}/poqm/sr/")
  end

  def test_pot_with_pot_in_name
    # Make sure multiple '.pot' aren't messing up the template detection by
    # incorrectly mangling more than the terminal .pot.
    # e.g. org.kde.potd.pot is org.kde.potd.po not org.kde.pod.po nor
    # org.kde.pod.pot
    # https://bugs.kde.org/show_bug.cgi?id=420574

    # NB: this is intentionally a different i18n_path to implicitly make sure
    # that works
    l = create_l10n('kdeplasmas-addons', 'kde-workspace')
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot-pot-name'), @dir)
    l.get(@dir)
    assert_path_exist("#{@dir}/po/de/org.kde.potd.po")
  end

  def test_modern_get
    # Modern getting doesn't rely on template detection.
    # Since the move to gitlab l10n sports a different directory structure
    # which enables us to blanket handle entire directories. To that end
    # .pot detection was removed in place of always using the entire directory
    # (- filtered stuff anyway).
    # Also relates to https://bugs.kde.org/show_bug.cgi?id=424031

    l = create_l10n('kcoreaddons', 'kcoreaddons')
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('kcoreaddons'), @dir)
    l.get(@dir)

    assert_path_exist("#{@dir}/po")
    # These are not mentioned in messages.sh but we want them!
    # Legeacy behavior would be to only fetch translations for templates
    # found in Messages.sh. The modern behavior is to exclude unwanted things.
    # https://bugs.kde.org/show_bug.cgi?id=424031
    contents = Dir.chdir("#{@dir}/po/de") { Dir.glob("**/**") }
    assert_equal(%w[kdirwatch.po kf5_entry.desktop].sort, contents.sort)
    # This excludes scripty managed artifacts  (get automaticaly folded back into their original file by l10n scripty):
    # - kdirwatch._json_.po
    # - kdirwatch_xml_mimetypes.po
    # - l10n._desktop_.po
    # - org.kde.kdirwatch.appdata.po
    # - org.kde.kdirwatch.metainfo.po

    assert(File.read("#{@dir}/CMakeLists.txt").include?('ki18n_install(po)'))
  end

  def test_po_already_exists
    # A select few repos already contain the po,qm,docbooks because of new tech that imports them back into
    # git from svn. Make sure this doesn't blow up.

    l = create_l10n('kcoreaddons', 'kcoreaddons')
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('kcoreaddons'), @dir)
    FileUtils.mkpath("#{@dir}/po/de")
    FileUtils.touch("#{@dir}/po/de/kdirwatch.po")
    assert_raises ReleaseMe::TranslationUnit::InstallMissingError do
      # Should raise if the cmakelists is malformed
      l.get(@dir)
    end
    # Correct the cmakelists and it should pass
    File.open("#{@dir}/CMakeLists.txt", 'a') { |f| f.write("ki18n_install(po)\n") }
    l.get(@dir)

    assert_path_exist("#{@dir}/po")
    contents = Dir.chdir("#{@dir}/po/de") { Dir.glob("**/**") }
    assert_equal(%w[kdirwatch.po].sort, contents.sort)
    # Do only expect kdirwatch.po. We want nothing else!

    assert(File.read("#{@dir}/CMakeLists.txt").include?('ki18n_install(po)'))
  end

  # kded only has manpages to translate, do not fail on this
  def test_manpages_already_exists
    # A select few repos already contain the po,qm,docbooks because of new tech that imports them back into
    # git from svn. Make sure this doesn't blow up.

    l = create_l10n('kded', 'kded')
    l.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('kded'), @dir)
    assert_raises ReleaseMe::TranslationUnit::InstallMissingError do
      # Should raise if the cmakelists is malformed
      l.get(@dir)
    end
    # Correct the cmakelists and it should pass
    File.open("#{@dir}/CMakeLists.txt", 'a') { |f| f.write("kdoctools_install(po)\n") }
    l.get(@dir)

    assert_path_exist("#{@dir}/po")
    contents = Dir.chdir("#{@dir}/po/de") { Dir.glob("**/**") }
    assert_equal(%w[man-kded5.8.docbook].sort, contents.sort)
    # Do only expect man-kded5.8.docbook. We want nothing else!

    assert(File.read("#{@dir}/CMakeLists.txt").include?('kdoctools_install(po)'))
  end  
end
