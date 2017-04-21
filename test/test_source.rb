require 'fileutils'

require_relative 'lib/testme'
require_relative '../lib/releaseme/git'
require_relative '../lib/releaseme/source'

# FIXME: source should be tested not only with git but also svn

class TestSource < Testme
    def setup
        @dir = "tmp_src_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        @gitTemplateDir = "tmp_src_git_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        %x[git init #{@gitTemplateDir}]
        assert_path_exist(@gitTemplateDir)
        Dir.chdir(@gitTemplateDir) do
            File.open("file", "w") { }
            assert_path_exist("file")
            %x[git add file]
            %x[git commit -m 'import']
        end
    end

    def teardown
        FileUtils.rm_rf(@gitTemplateDir)
        FileUtils.rm_rf(@dir)
    end

    def test_get
        FileUtils.rm_rf(@dir)

        s = ReleaseMe::Source.new()
        s.target = @dir
        v = ReleaseMe::Git.new()
        v.repository = @gitTemplateDir

        s.get(v)
        assert_path_exist(@dir)

        # Also do not fail on subsequent gets
        s.get(v)
        assert_path_exist(@dir)

        # Finally... we still can get
        FileUtils.rm_rf(@dir)
        s.get(v)
        assert_path_exist(@dir)
    end

    def test_target
        s = ReleaseMe::Source.new()
        assert_equal(s.target, nil)

        s.target = @dir
        assert_equal(s.target, @dir)

        s.target = nil
        assert_equal(s.target, nil)
    end

    def test_cleanup
        s = ReleaseMe::Source.new()
        s.target = @dir

        FileUtils.rm_rf(@dir)
        Dir.mkdir(@dir)
        s.cleanup()
        assert_path_not_exist(@dir)

        s.cleanup()
        assert_path_not_exist(@dir)
    end
end
