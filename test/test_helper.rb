formatters = []

begin
  require 'codeclimate-test-reporter'
  formatters << CodeClimate::TestReporter::Formatter
rescue LoadError
  warn 'codeclimate reporter not available, not sending reports to server'
end

begin
  require 'coveralls'
  formatters << Coveralls::SimpleCov::Formatter
rescue LoadError
  warn 'coveralls reporter not available, not sending reports to server'
end

begin
  require 'pullreview/coverage_reporter'
  formatters << PullReview::Coverage::Formatter
rescue LoadError => e
  warn 'pullreview reporter not available, not sending reports to server'
end

require 'simplecov'
SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter[*formatters]
end

Dir.chdir(File.dirname(__FILE__)) do
  Dir.glob('test_*.rb').each do |testfile|
    next if File.basename(testfile) == File.basename(__FILE__)
    next if File.basename(testfile).include?('blackbox')
    puts "Adding Test File: #{testfile}"
    require_relative testfile
  end
end
