#--
# Copyright (C) 2014 Harald Sitter <apachelogger@ubuntu.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License or (at your option) version 3 or any later version
# accepted by the membership of KDE e.V. (or its successor approved
# by the membership of KDE e.V.), which shall act as a proxy
# defined in Section 14 of version 3 of the license.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

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
