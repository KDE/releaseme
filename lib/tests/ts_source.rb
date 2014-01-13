require "fileutils"
require "test/unit"

require_relative "../source"

class TestSource < Test::Unit::TestCase
    def setup
        p ">>>>>>need testsource::test_clean"
        @dir = "tmp_src_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        @gitTemplateDir = "tmp_src_git_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        %x[git init #{@gitTemplateDir}]
        assert(File::exists?(@gitTemplateDir))
    end

    def teardown
        FileUtils.rm_rf(@gitTemplateDir)
        FileUtils.rm_rf(@dir)
    end

    def test_get
        FileUtils.rm_rf(@dir)

        s = Source.new()
        s.target = @dir
        v = Git.new()
        v.repository = @gitTemplateDir

        s.get(v)
        assert(File::exists?(@dir))

        # Also do not fail on subsequent gets
        s.get(v)
        assert(File::exists?(@dir))

        # Finally... we still can get
        FileUtils.rm_rf(@dir)
        s.get(v)
        assert(File::exists?(@dir))
    end

    def test_target
        s = Source.new()
        assert_equal(s.target, nil)

        s.target = @dir
        assert_equal(s.target, @dir)

        s.target = nil
        assert_equal(s.target, nil)
    end

    def test_cleanup
        s = Source.new()
        s.target = @dir

        FileUtils.rm_rf(@dir)
        Dir.mkdir(@dir)
        s.cleanup()
        assert(!File::exists?(@dir))

        s.cleanup()
        assert(!File::exists?(@dir))
    end
end
