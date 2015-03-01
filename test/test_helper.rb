begin
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
rescue LoadError
  warn 'codeclimate reporter not available, not sending reports to server'
end

require 'simplecov'
SimpleCov.start

Dir.chdir(File.dirname(__FILE__)) do
  Dir.glob('test_*.rb').each do |testfile|
    next if File.basename(testfile) == File.basename(__FILE__)
    next if File.basename(testfile).include?('blackbox')
    puts "Adding Test File: #{testfile}"
    require_relative testfile
  end
end
