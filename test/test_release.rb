require_relative "lib/testme"

require_relative "../lib/git"
require_relative "../lib/release"

class TestRelease < Test::Unit::TestCase
    def setup
        # FIXME: code dupe in test_source
        Dir.chdir(File.dirname(__FILE__))
        @dir = "tmp_release_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        @gitTemplateDir = "tmp_release_git_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        %x[git init #{@gitTemplateDir}]
        assert(File::exists?(@gitTemplateDir))
        Dir.chdir(@gitTemplateDir) do
            File.open("file", "w") { }
            assert(File::exist?("file"))
            %x[git add file]
            %x[git commit -m 'import']
        end
        FileUtils.rm_rf(@dir + "*")
    end

    def teardown
        FileUtils.rm_rf(@gitTemplateDir)
        # Also drop tar/xz etc.
        Dir.glob("#{@dir}*").each do | file |
            p file
            FileUtils.rm_rf(file)
        end
    end

    def test_vcs_pure_virtual
        assert_raise(RuntimeError) { Vcs.new().get("") }
    end

    def test_kdegit
        vcs = Git.new
        vcs.repository = @gitTemplateDir

        r = Release.new(vcs)
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
