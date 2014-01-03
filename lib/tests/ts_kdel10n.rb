require "fileutils"
require "test/unit"

require_relative "../kdegitrelease.rb"

class TestKdeL10n < Test::Unit::TestCase
    def setup
        puts "TODO NEED TO TEST STABLE>>>>>>>>>"
        @dataDir = "data/"
        @repoDataDir = "#{@dataDir}/l10nrepo/"

        @module = "extragear"
        @section = "multimedia"

        @trunkUrl = "trunk/l10n-kde4/"
        @stableUrl = "branches/stable/l10n-kde4"

        @dir = "tmp_l10n_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        @svnTemplateDir = "tmp_l10n_repo_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        @svnCheckoutDir = "tmp_l10n_check_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join

        %x{svnadmin create #{@svnTemplateDir}}
        assert(File::exists?(@svnTemplateDir))

        %x{svn co file://#{Dir.pwd}/#{@svnTemplateDir} #{@svnCheckoutDir}}
        FileUtils.cp_r("#{@repoDataDir}/trunk", @svnCheckoutDir)
        FileUtils.cp_r("#{@repoDataDir}/branches", @svnCheckoutDir)
        Dir.chdir(@svnCheckoutDir)
        %x{svn add *}
        %x{svn ci -m 'yolo'}
        Dir.chdir("..")
    end

    def teardown
        FileUtils.rm_rf(@svnTemplateDir)
        FileUtils.rm_rf(@svnCheckoutDir)
        FileUtils.rm_rf(@dir)
    end

    def create
        l = KdeL10n.new(KdeL10n::TRUNK, @module, @section)
        l.target = "#{@dir}/l10n"
        return l
    end

    def test_0_attr
        l = create()

        assert_equal(l.target, "#{@dir}/l10n")
        assert_equal(l.type, KdeL10n::TRUNK)
        assert_equal(l.module, "extragear")
        assert_equal(l.section, "multimedia")
    end

    def test_0_repo_url_init
        l = create()
        assert_equal(l.type, KdeL10n::TRUNK)
        l.initRepoUrl("file://a")
        assert_equal(l.vcs.repository, "file://a/trunk//l10n-kde4/")
        l.initRepoUrl("file://a/")
        assert_equal(l.vcs.repository, "file://a/trunk//l10n-kde4/")
    end

    def test_find_templates
        l = create()

        templates = l.find_templates("data/multi-pot")
        assert_equal(templates.count, 2)

        templates = l.find_templates("data/single-pot")
        assert_equal(templates.count, 1)
    end

    # FIXME: need to check that *all* files are there!
    def test_get
        l = create()
        l.initRepoUrl("file://#{Dir.pwd}/#{@svnTemplateDir}")

        FileUtils.rm_rf(@dir)
        FileUtils.cp_r("data/single-pot", @dir)
        l.get(@dir)
        assert(File::exists?(@dir))
        assert(File::exists?("#{@dir}/po"))

        FileUtils.rm_rf(@dir)
        FileUtils.cp_r("data/multi-pot", @dir)
        l.get(@dir)
        assert(File::exists?(@dir))
        assert(File::exists?("#{@dir}/po"))
    end
end
