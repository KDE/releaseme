#--
# Copyright (C) 2014 Harald Sitter <sitter@kde.org>
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
require_relative '../lib/releaseme/xzarchive'

class TestXzArchive < Testme
  def setup
    @dir = 'tardiry-123'
    teardown # Make sure everything is clean...
    Dir.mkdir(@dir)
  end

  def teardown
    FileUtils.rm_rf(@dir)
    FileUtils.rm_rf(tar_file)
    FileUtils.rm_rf(xz_file)
  end

  def tar_file
    "#{@dir}.tar"
  end

  def xz_file
    "#{tar_file}.xz"
  end

  def test_attr_directory
    a = ReleaseMe::XzArchive.new
    assert_nil(a.directory)

    a.directory = @dir
    assert_equal(a.directory, @dir)
  end

  def test_attr_level
    a = ReleaseMe::XzArchive.new
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
    a = ReleaseMe::XzArchive.new
    a.directory = @dir

    a.level = 1
    ret = a.create
    assert_equal(true, ret)
    assert_path_exist(xz_file)
    refute_path_exist(tar_file)
  end

  # Bogus compression level.
  # Must return false.
  # Must not have @dir.tar.
  # Must not have @dir.tar.xz
  def test_create_invalid_level
    a = ReleaseMe::XzArchive.new
    a.directory = @dir

    a.level = -1
    ret = a.create
    assert_equal(false, ret)
    refute_path_exist(tar_file)
    refute_path_exist(xz_file)
  end

  # Directory does not exist.
  # Must return false.
  # Must not have @dir.tar.
  # Must not have @dir.tar.xz
  def test_create_invalid_dir
    a = ReleaseMe::XzArchive.new
    a.directory = @dir

    d = 'test_create_invalid_dir-1.2.3'
    a.directory = d
    ret = a.create
    assert_equal(false, ret)
    refute_path_exist(tar_file)
    refute_path_exist(xz_file)
  end
end
