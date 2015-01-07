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

require_relative "../lib/svn"

class TestSvn < Test::Unit::TestCase
    def setup
        @svnCheckoutDir = Dir.pwd + "/tmp_check_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        @svnRepoDir = Dir.pwd + "/tmp_repo_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        %x[svnadmin create #{@svnRepoDir}]
        assert(File::exists?(@svnRepoDir))
    end

    def teardown
        FileUtils.rm_rf(@svnRepoDir)
        FileUtils.rm_rf(@svnCheckoutDir)
    end

    def populateRepo
        `svn co file://#@svnRepoDir #@svnCheckoutDir`
        `echo "yolo" > #@svnCheckoutDir/foo`
        Dir.mkdir(@svnCheckoutDir + "/dir")
        `echo "oloy" > #@svnCheckoutDir/dir/file`
        Dir.chdir(@svnCheckoutDir)
        `svn add *`
        `svn ci -m 'I am a troll'`
        Dir.chdir("..")
    end

    def validRepo
        s = Svn.new()
        s.repository = "file://#{@svnRepoDir}"
        return s
    end

    def test_cat
        populateRepo()
        s = validRepo()

        # Valid file.
        ret = s.cat("/foo")
        assert_equal($?.to_i, 0)
        assert_equal(ret, "yolo\n")

        # Invalid file.
        ret = s.cat("/bar")
        assert_not_equal($?.to_i, 0)
        assert_equal(ret, "")
    end

    def test_exists
        populateRepo()
        s = validRepo()

        # Valid file.
        ret = s.exist?("/foo")
        assert_equal(ret, true)

        # Invalid file.
        ret = s.exist?("/bar")
        assert_equal(ret, false)
    end

    def test_list
        populateRepo()
        s = validRepo()

        # Valid path.
        ret = s.list()
        assert_equal(ret, "dir/\nfoo\n")

        # Invalid path.
        ret = s.list("/invalid")
        assert_equal(ret, "")

        # Valid path other than /
        ret = s.list("/dir")
        assert_equal(ret, "file\n")
    end

    def test_export
        tmpDir = Dir.pwd + "/tmp_svn_export_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        Dir.mkdir(tmpDir)

        populateRepo()
        s = validRepo()

        # Valid target and path
        ret = s.export("#{tmpDir}/file", "/dir/file")
        assert_equal(ret, true)
        assert(File::exists?("#{tmpDir}/file"))

        # Target dir does not exist
        ret = s.export("#{tmpDir}123/file", "/dir/file")
        assert_equal(ret, false)
        assert(!File::exists?("#{tmpDir}123/file"))

        # Invalid path
        ret = s.export("#{tmpDir}/file", "/dir/otherfile")
        assert_equal(ret, false)
        assert(!File::exists?("#{tmpDir}/otherfile"))

    ensure
        FileUtils.rm_rf(tmpDir)
    end

    def test_get_repo_valid
        s = Svn.new()
        s.repository = "file://#{@svnRepoDir}"
        s.get(@svnCheckoutDir)
        assert(File::exists?(@svnCheckoutDir))
        FileUtils.rm_rf(@svnCheckoutDir)
    end

    def test_get_repo_invalid
        s = Svn.new()
        s.repository = "file://foofooofoo"
        s.get(@svnCheckoutDir)
        assert(!File::exists?(@svnCheckoutDir))
        FileUtils.rm_rf(@svnCheckoutDir)
    end

    def test_clean
        populateRepo()
        s = validRepo()

        s.get(@svnCheckoutDir)
        s.clean!(@svnCheckoutDir)
        assert(!File::exists?("#@svnCheckoutDir/.svn"))
        assert(!File::exists?("#@svnCheckoutDir/dir/.svn"))
    end

end
