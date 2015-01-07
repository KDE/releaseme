require "fileutils"
require "test/unit"
require "tmpdir"

class TestBlackboxTarme < Test::Unit::TestCase
    def setup
        @tmpdir = Dir.mktmpdir("testme-#{self.class.to_s}")
        @testdir = "#{File.dirname(__FILE__)}"
        @datadir = "#{File.dirname(__FILE__)}/data"
    end

    def teardown
        FileUtils.rm_r(@tmpdir)
    end

    def test_git
        Dir.chdir(@tmpdir)

        origin = "trunk"
        version = "1.1.1.1"
        name = "libdebconf-kde"
        # FIXME: this really should be done through xzarchive somehow
        expected_dirname = "#{name}-#{version}"
        expected_tarname = "#{expected_dirname}.tar.xz"

        ret = system("ruby #{@testdir}/../tarme.rb --origin #{origin} --version #{version} #{name}")
        assert(ret)
        assert(File.exist?(expected_tarname))
        expected_files = %w[
            .
            CMakeLists.txt
            Messages.sh
            po/de/libdebconf-kde.po
        ]
        expected_files.each do |expected_file|
            assert(File.exist?("#{expected_dirname}/#{expected_file}"), "File #{expected_file} not found in directory")
        end

        # Move base directory out of the way and extract a canonical version from
        # the tar. Must have the same files!
        FileUtils.mv(expected_dirname, "#{expected_dirname}.old")
        assert(system("tar -xf #{expected_tarname}"))
        assert(File.exist?(expected_dirname))
        assert_equal(Dir.glob("#{expected_dirname}/**/**").sort, Dir.glob("#{expected_dirname}.old/**/**"))

        # FIXME: check release_data
    end
end
