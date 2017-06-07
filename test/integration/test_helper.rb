$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__)) # releaseme
$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__)) # testme
require 'testme'
require 'minitest/autorun'
