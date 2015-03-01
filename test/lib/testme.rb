require 'tmpdir'
require 'fileutils'
require 'test/unit'

class Testme < Test::Unit::TestCase
  attr_reader :tmpdir
  attr_reader :testdir
  attr_reader :datadir

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

  def priority_setup
    ENV['RELEASEME_SHUTUP'] = 'true'
    @tmpdir = Dir.mktmpdir("testme-#{self.class}")
    @testdir = "#{File.expand_path(File.dirname(File.dirname(__FILE__)))}"
    @datadir = "#{@testdir}/data"
    @pwdir = Dir.pwd
    Dir.chdir(@tmpdir)
    setup_git
  end

  def priority_teardown
    teardown_git
    Dir.chdir(@pwdir)
    FileUtils.rm_rf(@tmpdir)
  end

  def data(path)
    path = path.partition('data/').last if path.start_with?('data/')
    "#{@datadir}/#{path}"
  end
end
