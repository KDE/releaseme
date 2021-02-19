# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017 Harald Sitter <sitter@kde.org>

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

  def test_path
    a = ReleaseMe::XzArchive.new
    a.directory = @dir
    a.level = 1

    ret = a.create

    assert ret
    assert_equal "#{Dir.pwd}/#{a.filename}", a.path
  end

  def test_format
    a = ReleaseMe::XzArchive.new

    a.directory = @dir
    assert(a.create)
    assert(system("unxz #{a.path}"))
    output = `file #{tar_file}`.strip
    assert($?.success?)
    assert(output.include?('(GNU)'),
      'tar file was not created with gnu format!')
  end

  def test_owner
    # Inside the tar the file owners should be kde:kde
    a = ReleaseMe::XzArchive.new
    a.directory = @dir
    assert(a.create)
    output = `tar -tvf #{a.path}`.strip
    assert($?.success?)
    assert_includes(output, 'kde/kde')
  end
end
