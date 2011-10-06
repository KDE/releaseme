require "fileutils"
require "test/unit"

require_relative "../kdegitrelease.rb"

class TestSvn < Test::Unit::TestCase
    def setup
        @svnTemplateDir = (0...50).map{ ('a'..'z').to_a[rand(26)] }.join
        system("svnadmin create #{@svnTemplateDir}")
        assert(File::exists?(@svnTemplateDir))
    end

    def teardown
        FileUtils.rm_rf(@svnTemplateDir)
    end

    def test_get
        d = "foo"
        s = Svn.new()

        s.repository = @svnTemplateDir
        s.get(d)
        assert(File::exists?(d))
        FileUtils.rm_rf(d)

        s.repository = "foofooofoo"
        s.get(d)
        assert(!File::exists?(d))
        FileUtils.rm_rf(d)
    end
end
