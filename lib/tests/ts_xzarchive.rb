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

    def test_create_valid
        a = XzArchive.new()
        a.directory = @dir

        # Proper setup.
        # Must have returned with true.
        # Must have @dir.tar.xz.
        # Must not have @dir.tar.
        FileUtils.rm_rf(tarFile())
        FileUtils.rm_rf(xzFile())
        a.level = 1
        ret = a.create()
        assert_equal(ret, true)
        assert(File::exists?(xzFile()))
        assert(!File::exists?(tarFile()))

        # Bogus compression level.
        # Must return with false.
        # Must not have @dir.tar.
        # Must not have @dir.tar.xz
        FileUtils.rm_rf(tarFile())
        FileUtils.rm_rf(xzFile())
        a.level = -1
        ret = a.create()
        assert_equal(ret, false)
        assert(!File::exists?(tarFile()))
        assert(!File::exists?(xzFile()))

        # Directory does not exist.
        # Must return with false
        # Must not have @dir.tar.
        # Must not have @dir.tar.xz
        FileUtils.rm_rf(tarFile())
        FileUtils.rm_rf(xzFile())
        d = "tmp_xz_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        a.directory = d
        ret = a.create()
        assert_equal(ret, false)
        assert(!File::exists?(tarFile()))
        assert(!File::exists?(xzFile()))
    end
end
