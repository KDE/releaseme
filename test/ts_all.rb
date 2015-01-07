unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

Dir.glob("#{File.dirname(__FILE__)}/test_*.rb").each do |testfile|
    next if File.basename(testfile) == File.basename(__FILE__)
    next if File.basename(testfile).include?("blackbox")
    puts "Adding Test File: #{testfile}"
    require_relative testfile
end
