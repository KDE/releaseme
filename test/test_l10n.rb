#--
# Copyright (C) 2015-2017 Harald Sitter <sitter@kde.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License or (at your option) version 3 or any later version
# accepted by the membership of KDE e.V. (or its successor approved
# by the membership of KDE e.V.), which shall act as a proxy
# defined in Section 14 of version 3 of the license.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require 'fileutils'

require_relative 'lib/testme'
require_relative '../lib/releaseme/l10n.rb'
require_relative '../lib/releaseme/l10nstatistics.rb'
require_relative '../lib/releaseme/documentation.rb'

# FIXME: test stable

class TestL10n < Testme
  def setup
    @repo_data_dir = data('l10nrepo/')

    @i18n_path = 'extragear-multimedia'

    @trunk_url = 'trunk/l10n-kf5/'
    @stable_url = 'branches/stable/l10n-kf5'

    @dir = 'tmp_l10n'
    @svn_template_dir = 'tmp_l10n_repo'
    @svn_checkout_dir = 'tmp_l10n_check'

    `svnadmin create #{@svn_template_dir}`
    assert(File.exist?(@svn_template_dir))

    `svn co file://#{Dir.pwd}/#{@svn_template_dir} #{@svn_checkout_dir}`
    FileUtils.cp_r("#{@repo_data_dir}/trunk", @svn_checkout_dir)
    FileUtils.cp_r("#{@repo_data_dir}/branches", @svn_checkout_dir)
    Dir.chdir(@svn_checkout_dir) do
      `svn add *`
      `svn ci -m 'yolo'`
    end
  end

  def teardown
    FileUtils.rm_rf(@svn_template_dir)
    FileUtils.rm_rf(@svn_checkout_dir)
    FileUtils.rm_rf(@dir)
  end

  def create_l10n(name = 'amarok', i18n_path = @i18n_path,
                  origin: ReleaseMe::L10n::TRUNK)
    l = ReleaseMe::L10n.new(origin, name, i18n_path)
    l.target = "#{@dir}/l10n"
    l
  end

  def test_find_templates
    l = create_l10n

    templates = l.find_templates(data('multi-pot'), skip_dir: nil)
    assert_equal(templates.count, 2)

    templates = l.find_templates(data('single-pot'), skip_dir: nil)
    assert_equal(templates.count, 1)
  end

  def test_get_po
    # For visual string consinstency we actually interpolate pointlessly below.
    # rubocop:disable Style/UnneededInterpolation

    l = create_l10n
    l.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    l.get(@dir)
    assert(File.exist?("#{@dir}"))
    assert(File.exist?("#{@dir}/CMakeLists.txt"))
    assert(!File.exist?("#{@dir}/l10n")) # temp dir must not be there
    assert(File.exist?("#{@dir}/po"))
    assert(File.exist?("#{@dir}/po/de/amarok.po"))
    assert(!File.exist?("#{@dir}/poqm")) # qt translation dir must not be there

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-pot'), @dir)
    l.get(@dir)
    assert(File.exist?("#{@dir}"))
    assert(File.exist?("#{@dir}/CMakeLists.txt"))
    assert(!File.exist?("#{@dir}/l10n")) # temp dir must not be there
    assert(File.exist?("#{@dir}/po"))
    assert(File.exist?("#{@dir}/po/de/amarok.po"))
    assert(File.exist?("#{@dir}/po/de/amarokcollectionscanner.po"))
  end

  def test_get_po_elsewhere
    l = create_l10n
    l.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")

    @elsewhere = "#{Dir.pwd}/elsewhere_tmp_l10n"

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    l.get(@dir, @elsewhere, edit_cmake: false)
    assert_path_exist("#{@elsewhere}/de/amarok.po")
  end

  def test_get_po_absolute_srcdir
    # Make sure we can pass an absolute dir as srcdir param.
    l = create_l10n
    l.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    l.get(File.absolute_path(@dir))
    assert_path_exist("#{@dir}/po/de/amarok.po")
  end

  def test_get_po_edit_cmake
    l = create_l10n
    l.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    l.get(@dir, edit_cmake: true)
    assert(File.exist?("#{@dir}/CMakeLists.txt"))
    assert_include(File.read("#{@dir}/CMakeLists.txt"), 'ki18n_install(po)')
  end

  def test_get_po_no_edit_cmake
    l = create_l10n
    l.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    l.get(@dir, edit_cmake: false)
    assert(File.exist?("#{@dir}/CMakeLists.txt"))
    assert_not_include(File.read("#{@dir}/CMakeLists.txt"), 'ki18n_install(po)')
  end

  def test_statistics
    l = create_l10n
    l.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-pot'), @dir)
    l.get(@dir)

    statistics = ReleaseMe::L10nStatistics.new
    statistics.gather!("#{@dir}/po")
    assert_equal({"de"=>{:all=>4,
                    :shown=>3,
                    :notshown=>1,
                    :percentage=>75.0},
                "fr"=>{:all=>4,
                    :shown=>4,
                    :notshown=>0,
                    :percentage=>100.0}}, statistics.stats)
  end

  def test_variable_potname
    l = create_l10n
    l.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('variable-pot'), @dir)
    assert_raises RuntimeError do
      l.get(@dir)
    end
  end

  def test_space_and_declared_multi_pot
    l = create_l10n
    l.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('space-and-declared-multi-pot'), @dir)
    l.get(@dir)
    assert_path_exist("#{@dir}/po/de/amarok.po")
    assert_path_exist("#{@dir}/po/de/amarokcollectionscanner.po")
  end

  def test_find_templates_bogus
    l = create_l10n
    templates = l.find_templates(data('bogus-pot'), skip_dir: nil)
    assert_equal(templates, [])
  end

  def test_diff_output_some_not_found_all_not_found
    # When no translations were found we expect different output versus when
    # only some were not found.

    l = create_l10n
    l.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-pot'), @dir)
    l.get(@dir)

    ENV.delete('RELEASEME_SHUTUP') # Reset by testme setup

    some_missing_stdout = StringIO.open do |io|
      $stdout = io
      l.instance_variable_set(:@__logger, nil) # Reset
      l.print_missing_languages([l.languages.pop])
      io.string.strip
    end

    all_missing_stdout = StringIO.open do |io|
      $stdout = io
      l.instance_variable_set(:@__logger, nil) # Reset
      l.print_missing_languages(l.languages)
      io.string.strip
    end
    $stdout = STDOUT

    assert_not_empty(some_missing_stdout)
    assert_not_empty(all_missing_stdout)
    assert_not_equal(some_missing_stdout, all_missing_stdout)
  ensure
    $stdout = STDOUT
  end

  def test_script
    # https://techbase.kde.org/Localization/Concepts/Transcript

    l = create_l10n('ki18n', 'frameworks')
    l.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-pot-script'), @dir)
    l.get(@dir)

    assert_path_exist("#{@dir}/po/sr/scripts")
    assert_path_exist("#{@dir}/po/sr/scripts/ki18n5")
    assert_path_exist("#{@dir}/po/sr/scripts/libplasma5")
    assert_path_not_exist("#{@dir}/po/sr/scripts/proto")

    assert_path_exist("#{@dir}/po/sr/scripts/ki18n5/ki18n5.js")
    assert_path_exist("#{@dir}/po/sr/scripts/ki18n5/trapnakron.pmap")

    assert_path_exist("#{@dir}/po/sr/scripts/libplasma5/libplasma5.js")
    assert_path_exist("#{@dir}/po/sr/scripts/libplasma5/plasmoid.js")
  end

  def test_pot_detection_without_releaseme
    # Do not find templates in the releaseme directory itself.
    # If releaseme was cloned into a source directory (or submoduled')
    # we'd otherwise trip over test fixtures.
    # One such fixture is:
    assert_path_exist("#{__dir__}/data/variable-pot/Messages.sh")
    l = ReleaseMe::L10n.new(ReleaseMe::L10n::TRUNK, 'ki18n', 'frameworks')
    # Make sure this doesn't raise anything.
    pos = l.find_templates(__dir__)
    assert_empty(pos)
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

    l = create_l10n('ktuberling', 'kdegames')
    l.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")

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
  end


  def test_multi_pot_kde4
    # In KDE4 you could have foo_qt.po to mean anything. In KF5 based code this
    # explicitly means that this is a qt translation compiled to qm.
    # We'll assert that KDE4 origins are treated as previously expected, the new
    # behavior is checked elsewhere.

    l = create_l10n(origin: ReleaseMe::Origin::TRUNK_KDE4)
    l.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-pot-kde4'), @dir)
    l.get(@dir)

    assert(File.exist?("#{@dir}"))
    assert(File.exist?("#{@dir}/CMakeLists.txt"))
    assert(!File.exist?("#{@dir}/l10n")) # temp dir must not be there
    assert(File.exist?("#{@dir}/po"))
    assert(File.exist?("#{@dir}/po/de/amarok.po"))
    assert(File.exist?("#{@dir}/po/de/amarokcollectionscanner_qt.po"))

    assert_false(File.read("#{@dir}/CMakeLists.txt").include?('ecm_install_po_files_as_qm'))
  end

  def test_poqm
    # Qt strings get put into a foo_qt.po, they are meant to get installed via
    # ecm_install_po_files_as_qm from ECM.

    l = create_l10n('step', 'kdeedu')
    l.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")

    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-pot-qt'), @dir)
    l.get(@dir)

    assert_path_exist("#{@dir}/poqm")
    assert_path_exist("#{@dir}/po/de/step.po")
    assert_path_exist("#{@dir}/poqm/de/step_qt.po")

    assert(File.read("#{@dir}/CMakeLists.txt").include?('ki18n_install(po)'))
    assert(File.read("#{@dir}/CMakeLists.txt").include?('ecm_install_po_files_as_qm(poqm)'))
  end
end
