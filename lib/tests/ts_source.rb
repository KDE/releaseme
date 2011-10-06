require "fileutils"
require "test/unit"

require_relative "../kdegitrelease.rb"

class TestSource < Test::Unit::TestCase
    def setup
        @gitTemplateDir = (0...50).map{ ('a'..'z').to_a[rand(26)] }.join
        system("git init #{@gitTemplateDir}")
        assert(File::exists?(@gitTemplateDir))
    end

    def teardown
        FileUtils.rm_rf(@gitTemplateDir)
    end

    def test_get
        d = "foo"
        FileUtils.rm_rf(d)

        s = Source.new()
        s.target = d
        v = Git.new()
        v.repository = @gitTemplateDir

        s.get(v)
        assert(File::exists?(d))

        # Also do not fail on subsequent gets
        s.get(v)
        assert(File::exists?(d))

        # Finally... we still can get
        FileUtils.rm_rf(d)
        s.get(v)
        assert(File::exists?(d))
    end

    def test_target
        d = "foo"

        s = Source.new()
        assert_equal(s.target, nil)

        s.target = d
        assert_equal(s.target, d)

        s.target = nil
        assert_equal(s.target, nil)
    end

    def test_cleanup
        d = "foo"
        s = Source.new()
        s.target = d

        FileUtils.rm_rf(d)
        Dir.mkdir(d)
        s.cleanup()
        assert(!File::exists?(d))

        s.cleanup()
        assert(!File::exists?(d))
    end
end
