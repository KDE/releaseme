require 'simplecov'

formatters = []

begin
  require 'coveralls'
  formatters << Coveralls::SimpleCov::Formatter
rescue LoadError
  warn 'coveralls reporter not available, not sending reports to server'
end

# HTML formatter.
formatters << SimpleCov::Formatter::HTMLFormatter

SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter.new(formatters)
  add_filter do |src|
    # Special compat file for testing the compat code itself.
    next false if File.basename(src.filename) == 'compat_compat.rb'
    next false if File.basename(src.filename) == 'releaseme.rb'
    src.filename.match(%r{.+/lib/[^/]+.rb})
  end
end

# $LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'minitest/autorun'
