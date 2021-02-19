# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017 Harald Sitter <sitter@kde.org>

require 'net/http'
require 'open-uri'
require 'json'

require_relative 'logable'

module ReleaseMe
  # projects.kde.org API.
  module ProjectsAPI
    # Converts a Hash recursively to snake case keys.
    module Snake
      module_function

      def it(obj)
        if obj.is_a?(Array)
          snake_array(obj)
        elsif obj.is_a?(Hash)
          snake_hash(obj)
        else
          obj
        end
      end

      def snake_array(array)
        array.map { |x| Snake.it(x) }
      end

      def snake_hash(hash)
        Hash[hash.map { |k, v| [underscore(k), Snake.it(v)] }]
      end

      def underscore(k)
        return underscore_it(k.to_s).to_sym if k.is_a?(Symbol)
        return underscore_it(k.to_s).to_s if k.is_a?(String)
        k
      end

      def underscore_it(str)
        # Grab all lower case alphas (+digits) followed by an upcase alpha and
        # inject an underscore before the upcase.
        # Then downcase everything.
        # (e.g. stableKF5 => stable_KF5 => stable_kf5)
        str.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
      end
    end

    # Connection wrapper.
    class Connection
      prepend Logable

      def initialize
        @uri = URI.parse('https://projects.kde.org/api/v1')
      end

      def uri(path, **query)
        uri = @uri.dup
        path = path[0] == '/' ? path : path[1..-1]
        uri.path = "#{uri.path}#{path}"
        uri.query = URI.encode_www_form(query) unless query.empty?
        log_debug uri
        uri
      end

      def get(path, **query)
        log_debug "GET #{uri(path, **query)}"
        data = JSON.parse(uri(path, **query).open.read, symbolize_names: true)
        Snake.it(data)
      end
    end

    # OStruct-like helper to expose a hash as methods.
    module MethodStruct
      attr_reader :data

      def method_missing(name, *args)
        @data.fetch(name) { super }
      end

      def respond_to_missing?(name)
        @data.key?(name) || super
      end
    end

    # API Project model.
    class Project
      include MethodStruct

      # I18n model of API.
      class I18n
        include MethodStruct

        def initialize(data)
          @data = data
          # Convert none to more idiomatic nil.
          @data = @data.collect { |k, v| [k, v == 'none' ? nil : v] }.to_h
        end
      end

      def initialize(data, _connection)
        @data = data
        @data[:i18n] = I18n.new(data[:i18n])
      end
    end

    class << self
      def get(path, connection = Connection.new)
        Project.new(connection.get("/project/#{path}"), connection)
      end

      def get_by_repo(repo, connection = Connection.new)
        Project.new(connection.get("/repo/#{repo}"), connection)
      end

      def find(connection = Connection.new, **kwords)
        connection.get('/find', **kwords)
      end

      def list(path, connection = Connection.new)
        connection.get("/projects/#{path}")
      end
    end
  end
end
