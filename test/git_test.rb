# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2015-2020 Harald Sitter <sitter@kde.org>

require 'fileutils'

require_relative 'lib/testme'
require_relative '../lib/releaseme/git'

class TestGit < Testme
  module Silencer
    module_function

    def run(cmd)
      `#{cmd} 2>&1`
    end
  end

  attr_reader :remotedir

  def `(other)
    Silencer.run(other)
  end

  def setup_repo_content
    `git clone #{@remotedir} clone`
    Dir.chdir('clone') do
      File.write('abc', 'content')
      `git add abc`
      `git commit -a -m 'import'`
      `git push origin master`
    end
  ensure
    FileUtils.rm_rf('clone')
  end

  def setup
    # Create a test remote
    Dir.mkdir('remote')
    Dir.chdir('remote') do
      `git init --bare .`
    end
    @remotedir = "#{Dir.pwd}/remote"

    setup_repo_content

    # Teardown happens automatically when the @tmpdir is torn down
  end

  def test_init
    g = ReleaseMe::Git.new
    refute_nil(g)
    g.repository = '/repo'
    assert_equal('/repo', g.repository)
    assert_nil(g.branch)
    g.branch = 'brunch'
    assert_equal('/repo', g.repository)
    assert_equal('brunch', g.branch)
    assert_nil(g.hash)
  end

  def test_get
    g = ReleaseMe::Git.new
    g.repository = @remotedir
    g.get('clone')
    assert_path_exist('clone/abc')
    assert_equal('content', File.read('clone/abc'))
    refute_nil(g.hash)
  end

  def test_get_error
    g = ReleaseMe::Git.new
    g.repository = '/this/doesnt/exist'
    assert_raises ReleaseMe::Git::CloneError do
      g.get('clone')
    end
    refute_path_exist('clone/abc')
    assert_nil(g.hash)
  end

  def test_clean
    g = ReleaseMe::Git.new
    g.repository = @remotedir
    g.get('clone')
    assert_path_exist('clone/.git')
    g.clean!('clone')
    refute_path_exist('clone/.git')
  end

  def test_get_and_clean
    g = ReleaseMe::Git.new
    g.repository = @remotedir
    g.get('clone', clean: true)
    refute_path_exist('clone/.git')
  end

  def create_from_hash
    ReleaseMe::Git.from_hash('repository' => '/kitten', 'branch' => 'brunch')
  end

  def test_from_hash
    g = create_from_hash
    refute_nil(g)
    assert_equal('/kitten', g.repository)
    assert_equal('brunch', g.branch)
  end

  def test_to_s
    g = create_from_hash
    assert_equal('(git - /kitten [brunch])', g.to_s)
  end

  def test_exist
    g = ReleaseMe::Git.new
    g.repository = @remotedir
    assert(g.exist?)

    # And not
    g = ReleaseMe::Git.new
    g.repository = "/dev/null"
    refute(g.exist?)
  end
end
