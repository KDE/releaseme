require 'tmpdir'
require 'fileutils'

require_relative '../test_helper'

require 'minitest/unit'
require 'mocha/mini_test'
require 'webmock/minitest'

module TestMeExtension
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
    @testdir = File.expand_path(File.dirname(File.dirname(__FILE__))).to_s
    @datadir = "#{@testdir}/data"
    @pwdir = Dir.pwd
    Dir.chdir(@tmpdir)
    setup_git
    setup_env
    super
  end

  def after_teardown
    teardown_git
    Dir.chdir(@pwdir)
    FileUtils.rm_rf(@tmpdir)
    # Restore original env
    ENV.replace(@orig_env)
    super
  end

  def data(path)
    path = path.partition('data/').last if path.start_with?('data/')
    "#{@datadir}/#{path}"
  end

  def assert_path_exist(path, msg = nil)
    msg = message(msg) { "Expected path '#{path}' to exist" }
    assert File.exist?(path), msg
  end

  def refute_path_exist(path, msg = nil)
    msg = message(msg) { "Expected path '#{path}' to NOT exist" }
    refute File.exist?(path), msg
  end
end

class Testme < Minitest::Test
  prepend TestMeExtension

  # WARNING: with minitest one should extend through a prepend otherwise hooks
  #   such as mocha may not get properly applied and cause test malfunctions!
end

if Gem::Dependency.new('', '~> 2.4.0').match?('', RUBY_VERSION)
  # Only set SANITIZED_PREFIX_SUFFIX in tests. Actual lib code mustn't ever
  # set it as that'd bypass the test.
  module MkTmpDirOverlay
    def mktmpdir(*a)
      return super(a) if ENV['SANITIZED_PREFIX_SUFFIX']
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
end
