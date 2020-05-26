# SPDX-FileCopyrightText: 2014-2020 Harald Sitter <sitter@kde.org>
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

require 'fileutils'

require_relative 'lib/testme'
require_relative '../lib/releaseme/svn'
require_relative '../lib/releaseme/tmpdir'

class TestSvn < Testme
  # Initialize a persistent reference repo. This repo will get copied for each
  # test to start from a pristine state. svn is fairly expensive so creating
  # new repos when the content doesn't change is costing multiple seconds!
  # FIXME: code copy with l10n
  REFERENCE_TMPDIR, REFERENCE_REPO_PATH = begin
    tmpdir = ReleaseMe.mktmpdir(self.class.to_s) # cleaned via after_run hook
    repo_data_dir = data('svnrepo/')

    svn_template_dir = "#{tmpdir}/tmp_svnrepo_repo"

    assert_run('svnadmin', 'create', svn_template_dir)
    raise unless File.exist?(svn_template_dir)

    ReleaseMe.mktmpdir(self.class.to_s) do |checkout_dir|
      checkout_dir = File.join(checkout_dir, "checkout")
      assert_run('svn', 'co', "file://#{svn_template_dir}", checkout_dir)
      File.write("#{checkout_dir}/foo", 'yolo')
      Dir.mkdir("#{checkout_dir}/dir")
      File.write("#{checkout_dir}/dir/file", 'oloy')
      assert_run('svn', 'add', '--force', '.', chdir: checkout_dir)
      assert_run('svn', 'ci', '-m', 'I am a troll', chdir: checkout_dir)
    end

    [tmpdir, svn_template_dir]
  end

  Minitest.after_run do
    FileUtils.rm_rf(REFERENCE_TMPDIR)
  end

  def setup
    @svn_repo_dir = File.absolute_path('le_repo')
    @svn_checkout_dir = 'le_checkout'
    FileUtils.cp_r(REFERENCE_REPO_PATH, @svn_repo_dir)
    assert_path_exist(@svn_repo_dir)
  end

  def new_valid_repo
    s = ReleaseMe::Svn.new
    s.repository = "file:///#{@svn_repo_dir}"
    s
  end

  def test_cat
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
    s = new_valid_repo

    # Valid file.
    ret = s.exist?('/foo')
    assert_equal(true, ret)

    # Invalid file.
    ret = s.exist?('/bar')
    assert_equal(false, ret)
  end

  def test_list
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
