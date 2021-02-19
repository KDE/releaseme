# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017 Harald Sitter <sitter@kde.org>

require 'net/http'
require 'json'

module ReleaseMe
  module Jenkins
    # A connection wrapper to a jenkins instance.
    class Connection
      BASE_URI = URI::HTTPS.build(host: 'build.kde.org')
      API_SUFFIX = '/api/json'.freeze

      def initialize(uri = BASE_URI)
        @uri = uri
      end

      def get(path, query = nil)
        uri = @uri.dup
        uri.path = (path + API_SUFFIX).gsub(%r{/+}, '/')
        uri.query = query
        response = Net::HTTP.get_response(uri)
        response.value
        JSON.parse(response.body)
      end
    end

    # A jenkins job
    class Job
      # A job's build
      class Build
        attr_reader :path

        def ==(other)
          other.id == id
        rescue Net::HTTPExceptions
          false
        end

        def id
          data.fetch('id')
        end

        private

        def initialize(path, connection)
          @path = path
          @connection = connection
        end

        def data
          @data ||= @connection.get(@path)
        end
      end

      class << self
        def from_name_and_branch(name, branch, connection = Connection.new)
          return [] unless name && branch
          filter = 'tree=jobs[name,url],views[name]'
          jobs = connection.get('/', filter).fetch('jobs')
          job_name_start = "#{name} #{branch.tr('/', '-')} "
          jobs.select! { |x| x.fetch('name').start_with?(job_name_start) }
          jobs.collect { |x| new(x.fetch('url'), connection) }
        end

        def bad_jobs(name, branch, connection = Connection.new)
          from_name_and_branch(name, branch, connection).collect do |j|
            next unless block_given?
            yield j
          end
        end
      end

      attr_reader :url

      def display_name
        data.fetch('displayName')
      end

      def last_build
        build('lastBuild')
      end

      def last_successful_build
        build('lastSuccessfulBuild')
      end

      def last_stable_build
        build('lastStableBuild')
      end

      def last_completed_build
        build('lastCompletedBuild')
      end

      def building?
        last_completed_build != last_build
      end

      def sufficient_quality?
        # TODO: I am not sure ENV is a good idea. It may promote putting an
        # override in one's .bashrc if one gets annoyed by the query once too
        # often in the long run rendering the feature useless.
        # OTOH I am not sure I care
        case ENV['RELEASEME_CI_CHECK']
        when 'none'
          true
        when 'success'
          # When we deal with a quality override we want to apply it to the
          # completed build not the current one. If the current one is still
          # building our validation is always rubbish.
          last_successful_build == last_completed_build
        else
          last_stable_build == last_build
        end
      end

      private

      def initialize(url, connection)
        uri = URI.parse(url)
        @path = uri.path
        @url = url
        @connection = connection
      end

      def build(id)
        Build.new("#{@path}#{id}", @connection)
      end

      def data
        @data ||= @connection.get(@path)
      end
    end
  end
end
