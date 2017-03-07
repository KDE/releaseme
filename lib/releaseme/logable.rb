#--
# Copyright (C) 2015 Harald Sitter <sitter@kde.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License or (at your option) version 3 or any later version
# accepted by the membership of KDE e.V. (or its successor approved
# by the membership of KDE e.V.), which shall act as a proxy
# defined in Section 14 of version 3 of the license.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require 'logger'
begin
  require 'logger/colors'
rescue LoadError
  puts 'Logging colors are not available. Install logger-colors gem if desired'
end

require_relative 'requirements'

# Expands Objects with logging capabilities.
# This module can be included or prepended, prepend allows you to implement
# your own {#create_logger} which can either create a completely new Logger
# instance or can modify the existing one from {#logger}.
# Logable can extend modules and classes alike and will also add class methods
# if included in a class allowing logging from all possible vectors.
module ReleaseMe
  module Logable
    # Methods extending the Object a {Logable} is included in. All methods are
    # private by default.
    module Methods
      private

      # @!visibility public

      def shutup?
        ENV['RELEASEME_SHUTUP'] && !ENV['RELEASEME_DEBUG']
      end

      # Logs as info type
      # @param str [String] the string to log
      def log_info(str)
        logger.info(str) unless shutup?
      end

      # Logs as warning type
      # @param str [String] the string to log
      def log_warn(str)
        logger.warn(str) unless shutup?
      end

      # Logs as debug type
      # @param str [String] the string to log
      def log_debug(str)
        logger.debug(str) unless shutup?
      end

      # Creates a new Logger instance.
      # Default Loggers are set to INFO mode, log to stdout and use the context
      # name as progname to distinguish output from different classes/modules/etc.
      # @note This method will defer to super when used in a prepended context,
      #   this allows prepending the module and adding a create_logger method
      #   which can alter settings of the logger without having to create an
      #   entirely new one.
      # @return [Logger] instance {#logger} was set to
      def create_logger
        @__logger = Logger.new($stdout)
        @__logger.level = Logger::INFO
        @__logger.level = Logger::DEBUG if ENV['RELEASEME_DEBUG']
        logger.formatter = proc do |severity, _datetime, progname, msg|
          "#{severity} -- #{progname}: #{msg}\n"
        end
        # Module classes are not useful, use the actual module name if we are
        # mixed into a module.
        if self.class == Module || self.class == Class
          @__logger.progname = "#{self.class}|#{self}"
        else
          @__logger.progname = self.class.to_s
        end
        @__logger = super if defined?(super)
        @__logger
      end

      # Gets the logger.
      # This method lazy-creates a logger if none exists yet in the present
      # context.
      # @return [Logger] as returned from {#create_logger} or cache
      def logger
        @__logger ||= create_logger
      end
    end

    extend Methods
    # @!parse extend Methods

    # @!visibility private
    def self.prepended(base)
      base.extend(Methods)
      base.prepend(Methods)
    end

    # @!visibility private
    def self.included(base)
      base.extend(Methods)
      base.include(Methods)
    end
  end
end
