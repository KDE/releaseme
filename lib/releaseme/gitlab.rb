# frozen_string_literal: true

# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017-2022 Harald Sitter <sitter@kde.org>

require 'erb'
require 'net/http'
require 'json'

module ReleaseMe
  module GitLab
    # A connection wrapper to a jenkins instance.
    class Connection
      BASE_URI = URI::HTTPS.build(host: 'invent.kde.org')
      API_PREFIX = '/api/v4/'

      def initialize(uri = BASE_URI)
        @uri = uri
      end

      def get(path, query = nil)
        uri = @uri.dup
        uri.path = (API_PREFIX + path)
        uri.query = query
        response = Net::HTTP.get_response(uri)
        response.value
        JSON.parse(response.body)
      end
    end

    class Pipeline
      class << self
        def each_from_repository_and_branch(repository, branch, connection = Connection.new, &block)
          path = ERB::Util.url_encode(repository.split(':', 2)[-1])

          page = 0
          loop do
            pipelines = connection.get("projects/#{path}/pipelines", URI.encode_www_form(page: page, ref: branch))
            break if pipelines.empty?

            # scripty makes commits that get skipped, ignore their pipelines
            pipelines = pipelines.reject { |x| x['status'] == 'skipped' }
            pipelines.each { |x| block.call(x) }
            break unless pipelines.empty?

            page += 1
          end
        end
      end
    end
  end
end
