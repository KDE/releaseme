# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2011-2019 Harald Sitter <sitter@kde.org>

require 'fileutils'

require_relative 'lib/testme'
require_relative '../lib/releaseme/git'
require_relative '../lib/releaseme/source'

class TestSource < Testme
  def setup
    @dir = "tmp_src_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
    @gitTemplateDir = "tmp_src_git_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
    `git init #{@gitTemplateDir}`
    assert_path_exist(@gitTemplateDir)
    Dir.chdir(@gitTemplateDir) do
      File.write('file', '')
      assert_path_exist('file')
      `git add file`
      `git commit -m 'import'`
    end
  end

  def teardown
    FileUtils.rm_rf(@gitTemplateDir)
    FileUtils.rm_rf(@dir)
  end

  def test_get
    FileUtils.rm_rf(@dir)

    s = ReleaseMe::Source.new
    s.target = @dir
    v = ReleaseMe::Git.new
    v.repository = @gitTemplateDir

    s.get(v)
    assert_path_exist(@dir)
  end

  def test_target
    s = ReleaseMe::Source.new
    assert_nil(s.target)

    s.target = @dir
    assert_equal(s.target, @dir)

    s.target = nil
    assert_nil(s.target)
  end

  def test_cleanup
    s = ReleaseMe::Source.new
    s.target = @dir

    FileUtils.rm_rf(@dir)
    Dir.mkdir(@dir)
    s.cleanup
    refute_path_exist(@dir)

    s.cleanup
    refute_path_exist(@dir)
  end
end
