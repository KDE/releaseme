# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2015-2020 Harald Sitter <sitter@kde.org>

require 'fileutils'
require 'open3'
require 'tmpdir'

require_relative '../test_helper'

require 'minitest/autorun'
begin
  require 'mocha/minitest'
rescue LoadError # 1.0 changed the name, try older name as well for good measure
  require 'mocha/mini_test'
end
require 'webmock/minitest'

module TestMeExtension
  module TestMeClassExtension
    def testdir
      File.expand_path(File.dirname(File.dirname(__FILE__))).to_s
    end

    def datadir
      "#{testdir}/data"
    end

    def data(path)
      path = path.partition('data/').last if path.start_with?('data/')
      "#{datadir}/#{path}"
    end

    # see instance method. this is a raise-only variant for use in global
    # test hooks (outside test instances).
    def assert_run(*args)
      out, result = Open3.capture2e(*args)
      raise <<-ERROR unless result.success?
  === assert_run[#{args.join(' ')}] ===
  #{out.strip}
  ===
      ERROR
    end
  end

  def self.prepended(base)
    class << base
      prepend TestMeClassExtension
    end
  end

  attr_reader :tmpdir
  attr_reader :testdir
  attr_reader :datadir

  def initialize(*args)
    @dir = nil
    @git_config_name = nil
    @git_config_email = nil
    super
  end

  def setup_git
    if `git config --global user.email`.strip.empty?
      @git_config_email = true
      `git config --global user.email "you@example.com"`
    end
    if `git config --global user.name`.strip.empty?
      @git_config_name = true
      `git config --global user.name "Your Name"`
    end
  end

  def teardown_git
    `git config --global --unset user.email` unless @git_config_email.nil?
    `git config --global --unset user.name` unless @git_config_name.nil?
  end

  def setup_env
    ENV['GNUPGHOME'] = data('keyring')
  end

  def before_setup
    @orig_env = ENV.to_h # to_h causes a full deserialization
    ENV['RELEASEME_SHUTUP'] = 'true'
    ENV['SANITIZED_PREFIX_SUFFIX'] = '1'
    @tmpdir = Dir.mktmpdir("testme-#{self.class.to_s.tr(':', '_')}")
    ENV['TEST_SETUP'] = nil
    @testdir = self.class.testdir
    @datadir = self.class.datadir
    @pwdir = Dir.pwd
    Dir.chdir(@tmpdir)
    setup_git
    setup_env
    super
  end

  def after_teardown
    Dir.chdir(@pwdir)
    FileUtils.rm_rf(@tmpdir)
    # Restore original env
    ## Explicitly clear to be on the safe side. Sometimes restoring the env
    ## may bug out slightly (on windows).
    ENV.clear
    ENV.replace(@orig_env)
    teardown_git
    super
  end

  def data(path)
    self.class.data(path)
  end

  def assert_path_exist(path, msg = nil)
    msg = message(msg) { "Expected path '#{path}' to exist" }
    assert File.exist?(path), msg
  end

  def refute_path_exist(path, msg = nil)
    msg = message(msg) { "Expected path '#{path}' to NOT exist" }
    refute File.exist?(path), msg
  end

  # handy overload to assert a command succeeds and if not print its output
  def assert_run(*args)
    out, result = Open3.capture2e(*args)
    assert(result.success?, <<-ERROR)
=== assert_run[#{args.join(' ')}] ===
#{out.strip}
===
    ERROR
  end
end

class Testme < Minitest::Test
  prepend TestMeExtension

  # WARNING: with minitest one should extend through a prepend otherwise hooks
  #   such as mocha may not get properly applied and cause test malfunctions!
end

# Only set SANITIZED_PREFIX_SUFFIX in tests. Actual lib code mustn't ever
# set it as that'd bypass the test.
module MkTmpDirOverlay
  def mktmpdir(*)
    return super if ENV['SANITIZED_PREFIX_SUFFIX']
    raise 'Dir.mktmpdir must not be used! Use Releaseme.mktmpdir!'
  ensure
    ENV['SANITIZED_PREFIX_SUFFIX'] = nil
  end
end

# Prevent tests from using mktmpdir directly and instead expect them to go
# through our mktmpdir such that the prefix_suffix gets cleaned up.
# https://bugs.kde.org/show_bug.cgi?id=393011
class Dir
  class << self
    prepend MkTmpDirOverlay
  end
end
