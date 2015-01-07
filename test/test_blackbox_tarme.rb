require "fileutils"
require "tmpdir"

require_relative "lib/testme"

class TestBlackboxTarme < Testme
    def test_git
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
        old_dirname = "#{expected_dirname}.old"
        new_dirname = "#{expected_dirname}"
        FileUtils.mv(new_dirname, old_dirname)
        assert(system("tar -xf #{expected_tarname}"))
        assert(File.exist?(new_dirname))
        old_file_list = Dir.chdir(old_dirname) { Dir.glob("**/**") }
        new_file_list = Dir.chdir(new_dirname) { Dir.glob("**/**") }
        assert_equal(old_file_list.sort, new_file_list.sort)

        # FIXME: check release_data
    end
end
