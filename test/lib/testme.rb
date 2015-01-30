require 'tmpdir'
require 'fileutils'
require 'test/unit'

class Testme < Test::Unit::TestCase
  attr_reader :tmpdir
  attr_reader :testdir
  attr_reader :datadir

  def priority_setup
    ENV['RELEASEME_SHUTUP'] = 'true'
    @tmpdir = Dir.mktmpdir("testme-#{self.class}")
    @testdir = "#{File.expand_path(File.dirname(File.dirname(__FILE__)))}"
    @datadir = "#{@testdir}/data"
    Dir.chdir(@tmpdir)
  end

  def priority_teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def data(path)
    path = path.partition('data/').last if path.start_with?('data/')
    "#{@datadir}/#{path}"
  end
end
