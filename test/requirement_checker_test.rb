require 'fileutils'

require_relative 'lib/testme'
require_relative '../lib/releaseme/requirement_checker'

class TestRequirementChecker < Testme
  class ExecutableTest < Testme
    Executable = ReleaseMe::RequirementChecker::Executable

    def setup
      ENV['PATH'] = Dir.pwd
    end

    def make_exe(name)
      File.write(name, '')
      File.chmod(0o700, name)
    end

    def test_exec
      make_exe('gpg2')
      assert_equal "#{Dir.pwd}/gpg2", Executable.new('gpg2').find
      assert_nil Executable.new('foobar').find
    end

    def test_windows
      # windows
      ENV['RELEASEME_FORCE_WINDOWS']
      make_exe('gpg2.exe')
      make_exe('svn.com')

      ENV['PATHEXT'] = '.COM;.EXE'.downcase # downcase so this passes on Linux
      ENV['PATH'] = Dir.pwd

      assert_equal "#{Dir.pwd}/gpg2.exe", Executable.new('gpg2').find
      assert_equal "#{Dir.pwd}/svn.com", Executable.new('svn').find
      assert_nil Executable.new('foobar').find
    end
  end

  def assert_ruby_version_compatible(version)
    checker = ReleaseMe::RequirementChecker.new
    checker.instance_variable_set(:@ruby_version, version)
    assert(checker.send(:ruby_compatible?),
           "Ruby version #{version} NOT compatible but should be")
  end

  def assert_ruby_version_not_compatible(version)
    checker = ReleaseMe::RequirementChecker.new
    checker.instance_variable_set(:@ruby_version, version)
    assert(!checker.send(:ruby_compatible?),
           "Ruby version #{version} compatible but should not be")
    assert_raises { checker.check }
  end

  def with_path(path)
    orig_path = ENV.fetch('PATH')
    ENV['PATH'] = path
    yield
  ensure
    ENV['PATH'] = orig_path if orig_path
  end

  def test_versions
    compatibles = %w[
      2.2
      2.2.0
      2.2.1
      2.3
      2.3.1
      2.4
      2.4.1
      2.5
      2.5.1
    ]
    compatibles.each { |i| assert_ruby_version_compatible(i) }
    incompatibles = %w[
      1.9.0
      2.0
      2.0.99
      2.6
      2.6.1
    ]
    incompatibles.each { |i| assert_ruby_version_not_compatible(i) }
  end

  def all_binaries
    ReleaseMe::RequirementChecker.const_get(:REQUIRED_BINARIES)
  end

  def test_missing_binaries
    with_path('') do
      checker = ReleaseMe::RequirementChecker.new
      missing_binaries = checker.send(:missing_binaries)
      expected_missing_binaries = all_binaries
      assert_equal(expected_missing_binaries, missing_binaries)
      assert_raises { checker.check }
    end
  end

  def test_existing_binaries
    FileUtils.touch(all_binaries)
    FileUtils.chmod('+x', all_binaries)
    with_path(Dir.pwd) do
      missing_binaries = ReleaseMe::RequirementChecker.new.send(:missing_binaries)
      assert_equal([], missing_binaries)
    end
  end
end
