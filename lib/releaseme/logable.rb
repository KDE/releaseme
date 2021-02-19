# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2015 Harald Sitter <sitter@kde.org>

require 'logger'
begin
  require 'logger/colors'
rescue LoadError
  # entirely optional, don't even mention it unless global debug is enabled.
  if ENV['RELEASEME_DEBUG']
    puts 'W: Logging colors are not available. Install logger-colors gem if desired'
  end
end

require_relative 'requirements'
require_relative 'silencer'

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
      include Silencer

      private

      # @!visibility public

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

      # Logs as fatal type
      # @param str [String] the string to log
      def log_fatal(str)
        logger.fatal(str) unless shutup?
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
