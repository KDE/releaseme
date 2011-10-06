require "fileutils"
require "test/unit"

require_relative "../kdegitrelease.rb"

class TestKdeL10n < Test::Unit::TestCase
    def setup
        #@svnTemplateDir = (0...50).map{ ('a'..'z').to_a[rand(26)] }.join
        #system("svnadmin create #{@svnTemplateDir}")
        #assert(File::exists?(@svnTemplateDir))
    end

    def teardown
        #FileUtils.rm_rf(@svnTemplateDir)
    end

    def create
        l = KdeL10n.new(KdeL10n::TRUNK, "extragear", "multimedia")
        l.target = "foo/l10n"
        return l
    end

    def test_attr
        l = create()

        assert_equal(l.target, "foo/l10n")
        assert_equal(l.type, KdeL10n::TRUNK)
        assert_equal(l.module, "extragear")
        assert_equal(l.section, "multimedia")
    end

    def test_find_templates
        l = create()

        templates = l.find_templates("data/multi-pot")
        assert_equal(templates.count, 2)

        templates = l.find_templates("data/single-pot")
        assert_equal(templates.count, 1)
    end

    def test_get
        l = create()

        FileUtils.rm_rf("foo")
        FileUtils.cp_r("data/single-pot", "foo")
        l.get("foo")
        assert(File::exists?("foo"))
        assert(File::exists?("foo/po"))

        FileUtils.rm_rf("foo")
        FileUtils.cp_r("data/multi-pot", "foo")
        l.get("foo")
        assert(File::exists?("foo"))
        assert(File::exists?("foo/po"))
    end
end
