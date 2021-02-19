# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2015 Harald Sitter <sitter@kde.org>

require_relative 'lib/testme'

require_relative '../lib/releaseme/logable'

class FakeClass1
  prepend ReleaseMe::Logable

  def create_logger
    Logger.new(File::NULL)
  end
end

class FakeClass2 < FakeClass1
  attr_accessor :log_file
  attr_accessor :log_level

  def create_logger
    logger = Logger.new(log_file)
    logger.level = log_level
    logger.formatter = proc do |_severity, _datetime, _progname, msg|
      "#{msg}\n"
    end
    logger
  end
end

module M
  prepend ReleaseMe::Logable

  attr_reader :log_file
  module_function :log_file

  module_function

  def log_file=(file)
    @log_file = file
    logdev = Logger::LogDevice.new(file)
    logger.instance_variable_set(:@logdev, logdev)
  end

  def logit
    log_warn 'warn'
    log_info 'info'
  end

  def create
    logger.level = Logger::INFO
    logger.formatter = proc do |_severity, _datetime, _progname, msg|
      "#{msg}\n"
    end
  end
end

class C
  prepend ReleaseMe::Logable
  prepend M

  def self.log(logfile)
    logdev = Logger::LogDevice.new(logfile)
    logger.instance_variable_set(:@logdev, logdev)

    logger.level = Logger::INFO
    logger.formatter = proc do |_severity, _datetime, _progname, msg|
      "#{msg}\n"
    end

    log_warn 'warn'
    log_info 'info'
  end
end

class FakeClass3Prepend
  prepend ReleaseMe::Logable

  private

  def create_logger
    logger.level = Logger::WARN
    logger
  end
end

class TestLogable < Testme
  def setup
    ENV['RELEASEME_SHUTUP'] = nil
  end

  def test_privacy
    fake = FakeClass1.new
    assert_raises NoMethodError do
      fake.log_warn 'kitten'
    end
    assert_raises NoMethodError do
      fake.log_info 'kitten'
    end
    assert_raises NoMethodError do
      fake.log_debug 'kitten'
    end
  end

  def test_init
    fake = FakeClass1.new
    assert_equal(fake.instance_variables, []) # lazy init
    fake.send :log_debug, 'kitten'
    assert_equal(fake.instance_variables, [:@__logger]) # lazy init
  end

  def test_format
    fake = FakeClass2.new
    fake.log_file = __callee__.to_s
    fake.log_level = Logger::WARN
    fake.send :log_warn, 'kitten'
    assert_equal("kitten\n", File.read(fake.log_file).lines.last)
  end

  def test_level
    fake = FakeClass2.new
    fake.log_file = __callee__.to_s
    fake.log_level = Logger::INFO
    fake.send :log_warn, 'warn'
    fake.send :log_info, 'info'
    fake.send :log_debug, 'debug'
    assert_equal("warn\n", File.read(fake.log_file).lines[-2])
    assert_equal("info\n", File.read(fake.log_file).lines[-1])
  end

  def test_mixin_other_module
    M.create
    M.log_file = __callee__.to_s
    M.logit
    assert_equal("warn\n", File.read(M.log_file).lines[-2])
    assert_equal("info\n", File.read(M.log_file).lines[-1])
  end

  def test_mixin_instance
    c = C.new
    # Prepended M is private in the class. This is a bit naughty but whatever.
    c.send :create
    c.send :log_file=, __callee__.to_s
    c.send :logit
    assert_equal("warn\n", File.read(c.send :log_file).lines[-2])
    assert_equal("info\n", File.read(c.send :log_file).lines[-1])
  end

  def test_mixin_class
    # Prepended M is private in the class. This is a bit naughty but whatever.
    logfile = __callee__.to_s
    C.send :log, logfile
    assert_equal("warn\n", File.read(logfile).lines[-2])
    assert_equal("info\n", File.read(logfile).lines[-1])
  end

  def test_super_prepend
    fake = FakeClass3Prepend.new
    fake.send :create_logger
    logger = fake.send :logger
    refute_nil(logger)
    assert_equal(Logger::WARN, logger.level)
  end
end
