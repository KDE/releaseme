# SPDX-FileCopyrightText: 2014-2020 Harald Sitter <sitter@kde.org>
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

require 'fileutils'

require_relative 'lib/testme'
require_relative '../lib/releaseme/svn'

class TestSvn < Testme
  def setup
    @svn_checkout_dir = "#{Dir.pwd}/tmp_check_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
    @svn_repo_dir = "#{Dir.pwd}/tmp_repo_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
    system("svnadmin create #{@svn_repo_dir}", [:out] => File::NULL) || raise
    assert_path_exist(@svn_repo_dir)
  end

  def teardown
    FileUtils.rm_rf(@svn_repo_dir)
    FileUtils.rm_rf(@svn_checkout_dir)
  end

  def populate_repo
    `svn co file:///#{@svn_repo_dir} #{@svn_checkout_dir}`
    File.write("#{@svn_checkout_dir}/foo", 'yolo')
    Dir.mkdir("#{@svn_checkout_dir}/dir")
    File.write("#{@svn_checkout_dir}/dir/file", 'oloy')
    Dir.chdir(@svn_checkout_dir) do
      system('svn', 'add', *Dir.glob('*'), [:out] => File::NULL) || raise
      system('svn', 'ci', '-m', 'I am a troll', [:out] => File::NULL) || raise
    end
  end

  def new_valid_repo
    s = ReleaseMe::Svn.new
    s.repository = "file:///#{@svn_repo_dir}"
    s
  end

  def test_cat
    populate_repo
    s = new_valid_repo

    # Valid file.
    ret = s.cat('/foo')
    assert(s.send(:status).success?)
    assert_equal('yolo', ret)

    # Invalid file.
    ret = s.cat('/bar')
    refute(s.send(:status).success?)
    assert_equal('', ret)
  end

  def test_exists
    populate_repo
    s = new_valid_repo

    # Valid file.
    ret = s.exist?('/foo')
    assert_equal(true, ret)

    # Invalid file.
    ret = s.exist?('/bar')
    assert_equal(false, ret)
  end

  def test_list
    populate_repo
    s = new_valid_repo

    # Valid path.
    ret = s.list
    assert_equal("dir/\nfoo\n", ret)

    # Invalid path.
    ret = s.list('/invalid')
    assert_equal('', ret)

    # Valid path other than /
    ret = s.list('/dir')
    assert_equal('file', ret.strip)
  end

  def test_export
    tmpDir = Dir.pwd + "/tmp_svn_export_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
    Dir.mkdir(tmpDir)

    populate_repo
    s = new_valid_repo

    # Valid target and path
    ret = s.export("#{tmpDir}/file", '/dir/file')
    assert_equal(true, ret)
    assert_path_exist("#{tmpDir}/file")

    # Target dir does not exist
    assert_raises ReleaseMe::Svn::Error do
      s.export("#{tmpDir}123/file", '/dir/file')
    end
    refute_path_exist("#{tmpDir}123/file")

    # Invalid path
    ret = s.export("#{tmpDir}/file", '/dir/otherfile')
    assert_equal(false, ret)
    refute_path_exist("#{tmpDir}/otherfile")

  ensure
    FileUtils.rm_rf(tmpDir)
  end

  def test_get_repo_valid
    s = ReleaseMe::Svn.new
    s.repository = "file:///#{@svn_repo_dir}"
    ret = s.get(@svn_checkout_dir)
    assert_equal(true, ret)
    assert_path_exist(@svn_checkout_dir)
    FileUtils.rm_rf(@svn_checkout_dir)
  end

  def test_get_repo_invalid
    s = ReleaseMe::Svn.new
    s.repository = 'file://foofooofoo'
    assert_raises ReleaseMe::Svn::Error do
      s.get(@svn_checkout_dir)
    end
    refute_path_exist(@svn_checkout_dir)
    FileUtils.rm_rf(@svn_checkout_dir)
  end

  def test_clean
    populate_repo
    s = new_valid_repo

    s.get(@svn_checkout_dir)
    s.clean!(@svn_checkout_dir)
    refute_path_exist("#{@svn_checkout_dir}/.svn")
    refute_path_exist("#{@svn_checkout_dir}/dir/.svn")
  end

  def test_from_hash
    s = ReleaseMe::Svn.from_hash(repository: 'kitten')
    refute_nil(s)
    assert_equal('kitten', s.repository)
  end

  def test_to_s
    s = ReleaseMe::Svn.from_hash(repository: 'kitten')
    assert_equal('(svn - kitten)', s.to_s)
  end

  def test_get_with_clean
    populate_repo
    s = new_valid_repo

    s.get(@svn_checkout_dir, clean: true)
    refute_path_exist("#{@svn_checkout_dir}/.svn")
    refute_path_exist("#{@svn_checkout_dir}/dir/.svn")
  end

  def test_connection_closed
    # simulate the remote closing the connection. this can happen when
    # the connection limit is exhausted on the remote

    err = <<-STDERR
svn: E170013: Unable to connect to a repository at URL 'svn://anonsvn.kde.org/home/kde/trunk/l10n-kf5/wa/messages/kde-workspace'
svn: E210002: Network connection closed unexpectedly
    STDERR

    status = mock('status')
    status.stubs(:success?).returns(false)

    result = ReleaseMe::Svn::Result.new('svn foo')
    result.capture3(['', err, status])
    ex = assert_raises ReleaseMe::Svn::Error do
      result.maybe_raise
    end
    assert_equal([170013, 210002], ex.codes.sort)
  end
end
