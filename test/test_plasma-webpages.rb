require 'fileutils'

require_relative 'lib/testme'

require_relative '../lib/git'

require 'erb'

class Template
  def initalize
    @filename = '/home/jr/src/releaseme/releaseme/test/plasma-template-info.php.erb'
    @data = File.read(@filename)
    p "initalize: " + @data
  end

  def render
    p @data
    renderer = ERB.new(@data)
#    renderer.result(binding)
  end
end

class TestPlasmaWebpages < Testme
  def setup
  end

  def test_render
    ref = File.read(data('plasma-webpages/plasma-5.6.4.php'))
    assert_not_equal('', ref)
    template = Template.new
    template.render
  end
end
