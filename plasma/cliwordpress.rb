require 'optparse'

require_relative 'kdewordpress'

options = {
    :categories => [],
    :tags => []
}
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
    opts.on("--bodyfile [path]", "the page contents path") do |v|
        options[:body] = File.read(v)
    end
    opts.on("--categories [categories]", "the page categories, separed by ',' coma") do |v|
        options[:categories] = v.split(',')
    end
    opts.on("--tags [tags]", "the page tags, separed by ',' coma") do |v|
        options[:tags] = v.split(',')
    end
end.parse!

publish(options[:path], options[:title], options[:body], options[:categories], options[:tags])
