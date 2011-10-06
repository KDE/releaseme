require "test/unit"
require_relative "../kdegitrelease.rb"

class TestKdeGitRelease < Test::Unit::TestCase
    def setup
        @gitTemplateDir = (0...50).map{ ('a'..'z').to_a[rand(26)] }.join
        system("git init #{@gitTemplateDir}")
        assert(File::exists?(@gitTemplateDir))
        @dir = "foo"
        FileUtils.rm_rf(@dir + "*")
    end

    def teardown
        FileUtils.rm_rf(@gitTemplateDir)
        FileUtils.rm_rf(@dir + "*")
    end

    def test_vcs_pure_virtual
        assert_raise(RuntimeError) { Vcs.new().get("") }
    end

    def test_kdegit
        r = KdeGitRelease.new()
        r.vcs.repository = @gitTemplateDir
        r.source.target = @dir

        assert(!File::exists?(@dir))
        r.get()
        assert(File::exists?(@dir))

        assert(!File::exists?("#{@dir}.tar.xz"))
        r.archive()
        assert(File::exists?("#{@dir}.tar.xz"))

        assert(File::exists?(@dir))
        r.source.cleanup()
        assert(!File::exists?(@dir))
    end
end
