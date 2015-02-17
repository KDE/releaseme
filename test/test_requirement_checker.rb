require 'fileutils'

require_relative 'lib/testme'

require_relative '../lib/requirement_checker'

class TestRequirementChecker < Testme
  def assert_ruby_version_compatible(version)
    checker = RequirementChecker.new
    checker.instance_variable_set(:@ruby_version, version)
    assert(checker.send(:ruby_compatible?),
           "Ruby version #{version} NOT compatible but should be")
  end

  def assert_ruby_version_not_compatible(version)
    checker = RequirementChecker.new
    checker.instance_variable_set(:@ruby_version, version)
    assert(!checker.send(:ruby_compatible?),
           "Ruby version #{version} compatible but should not be")
  end

  def with_path(path)
    orig_path = ENV.fetch('PATH')
    ENV['PATH'] = path
    yield
  ensure
    ENV['PATH'] = orig_path if orig_path
  end

  def test_versions
    compatibles = %w(
      2.1
      2.1.0
      2.1.1
      2.2
      2.2.0
      2.2.1
    )
    compatibles.each { |i| assert_ruby_version_compatible(i) }
    incompatibles = %w(
      1.9.0
      2.0
      2.0.99
      2.3
      2.3.1
      2.4
      2.4.1
    )
    incompatibles.each { |i| assert_ruby_version_not_compatible(i) }
  end

  def all_binaries
    @all_binaries ||= %w(svn git tar xz msgfmt)
  end

  def test_missing_binaries
    with_path('') do
      missing_binaries = RequirementChecker.new.send(:missing_binaries)
      expected_missing_binaries = all_binaries
      assert_equal(expected_missing_binaries, missing_binaries)
    end
  end

  def test_existing_binaries
    FileUtils.touch(all_binaries)
    FileUtils.chmod('+x', all_binaries)
    with_path(Dir.pwd) do
      missing_binaries = RequirementChecker.new.send(:missing_binaries)
      assert_equal([], missing_binaries)
    end
  end
end
