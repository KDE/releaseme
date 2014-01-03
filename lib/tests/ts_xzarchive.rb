require "fileutils"
require "test/unit"

require_relative "../kdegitrelease.rb"

class TestXzArchive < Test::Unit::TestCase
    def setup
        @dir = Dir.pwd + "/tmp_xz_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        FileUtils.rm_rf(@dir)
    end

    def teardown
        FileUtils.rm_rf(@dir)
    end

    def tar(directory)
        return directory + ".tar"
    end

    def file(directory)
        return tar(directory) + ".xz"
    end

    def test_directory
        a = XzArchive.new()
        assert_equal(a.directory, nil)

        a.directory = @dir
        assert_equal(a.directory, @dir)
    end

    def test_rate
        a = XzArchive.new()
        a.directory = @dir
        assert_equal(a.level, 9)

        a.level = 5
        assert_equal(a.level, 5)
    end

    def test_create
        file_ = file(@dir)
        FileUtils.rm_rf(@dir)
        Dir.mkdir(@dir)

        a = XzArchive.new()
        a.directory = @dir

        FileUtils.rm_rf(file_)
        a.level = 1
        a.create()
        assert(File::exists?(file_))
        FileUtils.rm_rf(tar(@dir))

        FileUtils.rm_rf(file_)
        a.level = -1
        a.create()
        assert(!File::exists?(file_))
        FileUtils.rm_rf(tar(@dir))

        # On failure (e.g. wrong directory) neither tar nor xz should be present
        FileUtils.rm_rf(file_)
        d = "tmp_xz_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        a.directory = d
        a.create()
        assert(!File::exists?(tar(d)))
        assert(!File::exists?(file(d)))
    end
end
