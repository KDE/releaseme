require "fileutils"

require_relative "lib/testme"

require_relative "../lib/l10n.rb"
require_relative "../lib/l10nstatistics.rb"
require_relative "../lib/documentation.rb"

# FIXME: test stable

class TestL10n < Testme
    def setup
        @repoDataDir = data("l10nrepo/")

        @i18n_path = "extragear-multimedia"

        @trunkUrl = "trunk/l10n-kf5/"
        @stableUrl = "branches/stable/l10n-kf5"

        @dir = "tmp_l10n_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        @svnTemplateDir = "tmp_l10n_repo_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        @svnCheckoutDir = "tmp_l10n_check_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join

        `svnadmin create #{@svnTemplateDir}`
        assert(File.exist?(@svnTemplateDir))

        `svn co file://#{Dir.pwd}/#{@svnTemplateDir} #{@svnCheckoutDir}`
        FileUtils.cp_r("#{@repoDataDir}/trunk", @svnCheckoutDir)
        FileUtils.cp_r("#{@repoDataDir}/branches", @svnCheckoutDir)
        Dir.chdir(@svnCheckoutDir) do
          `svn add *`
          `svn ci -m 'yolo'`
        end
    end

    def teardown
        FileUtils.rm_rf(@svnTemplateDir)
        FileUtils.rm_rf(@svnCheckoutDir)
        FileUtils.rm_rf(@dir)
    end

    def create_l10n
        l = L10n.new(L10n::TRUNK, 'amarok', @i18n_path)
        l.target = "#{@dir}/l10n"
        l
    end

    def test_find_templates
        l = create_l10n

        templates = l.find_templates(data("multi-pot"))
        assert_equal(templates.count, 2)

        templates = l.find_templates(data("single-pot"))
        assert_equal(templates.count, 1)
    end

    def test_get_po
        l = create_l10n
        l.init_repo_url("file://#{Dir.pwd}/#{@svnTemplateDir}")

        FileUtils.rm_rf(@dir)
        FileUtils.cp_r(data("single-pot"), @dir)
        l.get(@dir)
        assert(File.exist?("#{@dir}"))
        assert(File.exist?("#{@dir}/CMakeLists.txt"))
        assert(!File.exist?("#{@dir}/l10n")) # temp dir must not be there
        assert(File.exist?("#{@dir}/po"))
        assert(File.exist?("#{@dir}/po/de/amarok.po"))

        FileUtils.rm_rf(@dir)
        FileUtils.cp_r(data("multi-pot"), @dir)
        l.get(@dir)
        assert(File.exist?("#{@dir}"))
        assert(File.exist?("#{@dir}/CMakeLists.txt"))
        assert(!File.exist?("#{@dir}/l10n")) # temp dir must not be there
        assert(File.exist?("#{@dir}/po"))
        assert(File.exist?("#{@dir}/po/de/amarok.po"))
        assert(File.exist?("#{@dir}/po/de/amarokcollectionscanner_qt.po"))
    end

    def test_statistics
        l = create_l10n
        l.init_repo_url("file://#{Dir.pwd}/#{@svnTemplateDir}")

        FileUtils.rm_rf(@dir)
        FileUtils.cp_r(data("multi-pot"), @dir)
        l.get(@dir)

        statistics = L10nStatistics.new
        statistics.gather!(@dir)
        assert_equal(statistics.stats, {"de"=>{:all=>4,
                                           :shown=>3,
                                           :notshown=>1,
                                           :percentage=>75.0},
                                        "fr"=>{:all=>4,
                                           :shown=>4,
                                           :notshown=>0,
                                           :percentage=>100.0}})
    end

  def test_variable_potname
    l = create_l10n
    l.init_repo_url("file://#{Dir.pwd}/#{@svnTemplateDir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('variable-pot'), @dir)
    assert_raises RuntimeError do
      l.get(@dir)
    end
  end

  def test_space_and_declared_multi_pot
    l = create_l10n
    l.init_repo_url("file://#{Dir.pwd}/#{@svnTemplateDir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('space-and-declared-multi-pot'), @dir)
    l.get(@dir)
    assert_path_exist("#{@dir}/po/de/amarok.po")
    assert_path_exist("#{@dir}/po/de/amarokcollectionscanner_qt.po")
  end

  def test_find_templates_bogus
    l = create_l10n
    templates = l.find_templates(data("bogus-pot"))
    assert_equal(templates, [])
  end

  def test_diff_output_some_not_found_all_not_found
    # When no translations were found we expect different output versus when
    # only some were not found.

    l = create_l10n
    l.init_repo_url("file://#{Dir.pwd}/#{@svnTemplateDir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data("multi-pot"), @dir)
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
end
