#--
# Copyright (C) 2014-2015 Harald Sitter <sitter@kde.org>
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

require 'fileutils'

require_relative 'lib/testme'

require_relative '../lib/svn'

class TestSvn < Testme
  def setup
    @svn_checkout_dir = "#{Dir.pwd}/tmp_check_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
    @svn_repo_dir = "#{Dir.pwd}/tmp_repo_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
    `svnadmin create #{@svn_repo_dir}`
    assert(File.exist?(@svn_repo_dir))
  end

  def teardown
    FileUtils.rm_rf(@svn_repo_dir)
    FileUtils.rm_rf(@svn_checkout_dir)
  end

  def populate_repo
    `svn co file://#{@svn_repo_dir} #{@svn_checkout_dir}`
    `echo "yolo" > #{@svn_checkout_dir}/foo`
    Dir.mkdir("#{@svn_checkout_dir}/dir")
    `echo "oloy" > #{@svn_checkout_dir}/dir/file`
    Dir.chdir(@svn_checkout_dir)
    `svn add *`
    `svn ci -m 'I am a troll'`
    Dir.chdir('..')
  end

  def new_valid_repo
    s = Svn.new
    s.repository = "file://#{@svn_repo_dir}"
    s
  end

  def test_cat
    populate_repo
    s = new_valid_repo

    # Valid file.
    ret = s.cat('/foo')
    assert_equal(0, $?.to_i)
    assert_equal("yolo\n", ret)

    # Invalid file.
    ret = s.cat('/bar')
    assert_not_equal(0, $?.to_i)
    assert_equal('', ret)
  end

  def test_exists
    populate_repo
    s = new_valid_repo

    # Valid file.
    ret = s.exist?('/foo')
    assert_equal(ret, true)

    # Invalid file.
    ret = s.exist?('/bar')
    assert_equal(ret, false)
  end

  def test_list
    populate_repo
    s = new_valid_repo

    # Valid path.
    ret = s.list
    assert_equal(ret, "dir/\nfoo\n")

    # Invalid path.
    ret = s.list('/invalid')
    assert_equal(ret, '')

    # Valid path other than /
    ret = s.list('/dir')
    assert_equal(ret, "file\n")
  end

  def test_export
    tmpDir = Dir.pwd + "/tmp_svn_export_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
    Dir.mkdir(tmpDir)

    populate_repo
    s = new_valid_repo

    # Valid target and path
    ret = s.export("#{tmpDir}/file", '/dir/file')
    assert_equal(ret, true)
    assert(File.exist?("#{tmpDir}/file"))

    # Target dir does not exist
    ret = s.export("#{tmpDir}123/file", '/dir/file')
    assert_equal(ret, false)
    assert(!File.exist?("#{tmpDir}123/file"))

    # Invalid path
    ret = s.export("#{tmpDir}/file", '/dir/otherfile')
    assert_equal(ret, false)
    assert(!File.exist?("#{tmpDir}/otherfile"))

  ensure
    FileUtils.rm_rf(tmpDir)
  end

  def test_get_repo_valid
    s = Svn.new
    s.repository = "file://#{@svn_repo_dir}"
    ret = s.get(@svn_checkout_dir)
    assert_equal(true, ret)
    assert(File.exist?(@svn_checkout_dir))
    FileUtils.rm_rf(@svn_checkout_dir)
  end

  def test_get_repo_invalid
    s = Svn.new
    s.repository = 'file://foofooofoo'
    s.get(@svn_checkout_dir)
    assert(!File.exist?(@svn_checkout_dir))
    FileUtils.rm_rf(@svn_checkout_dir)
  end

  def test_clean
    populate_repo
    s = new_valid_repo

    s.get(@svn_checkout_dir)
    s.clean!(@svn_checkout_dir)
    assert(!File.exist?("#{@svn_checkout_dir}/.svn"))
    assert(!File.exist?("#{@svn_checkout_dir}/dir/.svn"))
  end

  def test_from_hash
    s = Svn.from_hash(repository: 'kitten')
    assert_not_nil(s)
    assert_equal('kitten', s.repository)
  end

  def test_to_s
    s = Svn.from_hash(repository: 'kitten')
    assert_equal('(svn - kitten)', s.to_s)
  end
end
