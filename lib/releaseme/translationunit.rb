# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2007-2017 Harald Sitter <sitter@kde.org>

require 'thread'

require_relative 'origin'
require_relative 'source'
require_relative 'svn'
require_relative 'tmpdir'

# Base class for a {Source} that represents a translation unit. This notibly
# are either message translations as obtained by {L10n} or documentation
# translations as obtained by {Documentation}.
module ReleaseMe
  class TranslationUnit < Source
    # The VCS to use to obtain the l10n sources
    attr_reader :vcs
    # The type of the release (stable,trunk)
    attr_reader :type
    # The i18n base path to use in SVN (e.g. extragear-utils/)
    attr_reader :i18n_path

    # The project name this translation belongs to
    attr_reader :project_name

    # @deprecated use a {Origin}
    TRUNK  = Origin::TRUNK
    # @deprecated use a {Origin}
    STABLE = Origin::STABLE
    # @deprecated use a {Origin}
    LTS = Origin::LTS

    # Languages that will by default be dropped from the list of languages
    # obtained from SVN.
    DEFAULT_EXCLUDED_LANGUAGES = ENV.fetch('RELEASEME_EXCLUDE_LANGUAGES',
                                           'x-test').split(' ').freeze

    # anonsvn only allows 5 concurrent connections.
    THREAD_COUNT = 5

    def initialize(type, project_name, i18n_path, vcs: Svn.new)
      @type = type
      @i18n_path = i18n_path
      @project_name = project_name
      @vcs = vcs

      @languages = []
      @default_excluded_languages = nil

      validate_instace_variables

      init_repo_url(ENV.fetch('RELEASEME_SVN_REPO_URL',
                              'svn://anonsvn.kde.org/home/kde/'))
    end

    # @return Array<String> list of excluded languages, defaults to
    #   class const {DEFAULT_EXCLUDED_LANGUAGES}
    def default_excluded_languages
      @default_excluded_languages || DEFAULT_EXCLUDED_LANGUAGES
    end
    attr_writer :default_excluded_languages

    # FIXME: this name seems a bit meh
    def init_repo_url(base_url)
      repo_url = base_url
      repo_url += "/#{url_type_suffix}/#{url_l10n_dir}/"

      @vcs.repository = repo_url
    end

    def languages(excluded = [])
      excluded.concat(default_excluded_languages)
      languages = self.class.languages(@vcs).clone # do not modify the live list
      languages.delete_if { |l| excluded.include?(l) }
    end

    def languages_queue(excluded = nil, without: [])
      queue = Queue.new
      languages(excluded || without).each { |l| queue << l }
      queue
    end

    # FIXME: should we just go full abstract and forget about the specifics
    #   factory?
    # def vcs_l10n_path(lang)
    #   fail 'todo'
    # end
    #
    # def get(source_dir)
    #   fail 'todo'
    # end

    # FIXME: not tested
    def self.languages(vcs)
      # Cache this bugger to avoid double lookup for messages and documentation.
      # NOTE: this only is reasonable for as long as all derivaed classes have
      #       the same vcs configuration, so this is potentially dangerous.
      @languages ||= vcs.cat('subdirs').split($RS)
    end

    def self.languages=(l)
      @languages = l
    end

    private

    def blocking_thread_pool
      threads = Array.new(THREAD_COUNT) do
        Thread.new do
          Thread.current.abort_on_exception = true
          yield
        end
      end
      threads.each(&:join)
    end

    def each_language_with_tmpdir(queue = languages_queue)
      blocking_thread_pool do
        until queue.empty?
          begin
            lang = queue.pop(true)
          rescue ThreadError
            # When pop runs into an empty queue with non_block=true it raises
            # an exception. We'll simply continue with it as our loop should
            # naturally end anyway.
            next
          end
          ReleaseMe.mktmpdir(self.class.to_s) { |tmpdir| yield lang, tmpdir }
        end
      end
    end

    def url_type_suffix
      case type
      when Origin::TRUNK, Origin::TRUNK_KDE4
        'trunk'
      when Origin::STABLE, Origin::LTS, Origin::STABLE_KDE4
        'branches/stable'
      else
        raise "Unknown l10n type #{type}"
      end
    end

    # special translations for Plasma LTS
    def url_l10n_dir
      case type
      when Origin::TRUNK, Origin::STABLE
        return 'l10n-kf5'
      when Origin::LTS
        return 'l10n-kf5-plasma-lts'
      when Origin::TRUNK_KDE4, Origin::STABLE_KDE4
        return 'l10n-kde4'
      end
      # FIXME: move the concept of origins to project and make an Array
      # Then blanket assert the type validity in #init
      raise "Unknown l10n type #{type}"
    end

    def validate_instace_variables
      raise 'type must not be nil' unless @type
      raise 'i18n_path must not be nil' unless @i18n_path
      raise 'project_name must not be nil' unless @project_name
    end
  end
end
