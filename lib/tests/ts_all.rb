unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative "ts_cmakeeditor.rb"
require_relative "ts_kdegitrelease.rb"
require_relative "ts_kdel10n.rb"
require_relative "ts_project.rb"
require_relative "ts_source.rb"
require_relative "ts_svn.rb"
require_relative "ts_xzarchive.rb"
