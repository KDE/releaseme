require "fileutils"
require "test/unit"

require_relative "../xzarchive"

class TestXzArchive < Test::Unit::TestCase
    def setup
        @dir = Dir.pwd + "/tmp_xz_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        teardown() # Make sure everything is clean...
        Dir.mkdir(@dir)
    end

    def teardown
        FileUtils.rm_rf(@dir)
        FileUtils.rm_rf(tarFile())
        FileUtils.rm_rf(xzFile())
    end

    def tarFile()
        return @dir + ".tar"
    end

    def xzFile()
        return tarFile() + ".xz"
    end

    def test_attr_directory
        a = XzArchive.new()
        assert_equal(a.directory, nil)

        a.directory = @dir
        assert_equal(a.directory, @dir)
    end

    def test_attr_level
        a = XzArchive.new()
        a.directory = @dir
        assert_equal(a.level, 9)

        a.level = 5
        assert_equal(a.level, 5)
    end

    # Proper setup.
    # Must return true.
    # Must have @dir.tar.xz.
    # Must not have @dir.tar.
    def test_create_valid
        a = XzArchive.new()
        a.directory = @dir

        a.level = 1
        ret = a.create()
        assert_equal(ret, true)
        assert(File::exists?(xzFile()))
        assert(!File::exists?(tarFile()))
    end

    # Bogus compression level.
    # Must return false.
    # Must not have @dir.tar.
    # Must not have @dir.tar.xz
    def test_create_invalid_level
        a = XzArchive.new()
        a.directory = @dir

        a.level = -1
        ret = a.create()
        assert_equal(ret, false)
        assert(!File::exists?(tarFile()))
        assert(!File::exists?(xzFile()))
    end

    # Directory does not exist.
    # Must return false.
    # Must not have @dir.tar.
    # Must not have @dir.tar.xz
    def test_create_invalid_dir
        a = XzArchive.new()
        a.directory = @dir

        d = "tmp_xz_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        a.directory = d
        ret = a.create()
        assert_equal(ret, false)
        assert(!File::exists?(tarFile()))
        assert(!File::exists?(xzFile()))
    end
end
