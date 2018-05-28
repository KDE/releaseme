require 'optparse'

require_relative 'kdewordpress'

options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: cliwordpress.rb [options]"

    opts.on("--title [title]", "the page title") do |v|
        options[:title] = v
    end
    opts.on("--path [path]", "the page path") do |v|
        options[:path] = v
    end
    opts.on("--body [contents]", "the page contents") do |v|
        options[:body] = v
    end
end.parse!

publish(options[:path], options[:title], options[:body])
