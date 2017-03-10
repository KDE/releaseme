#--
# Copyright (C) 2007-2017 Harald Sitter <sitter@kde.org>
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

require 'thread'

require_relative 'origin'
require_relative 'source'
require_relative 'svn'

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

    # Obtained and valid languages
    attr_reader :languages
    # Found templates
    attr_reader :templates

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
    DEFAULT_EXCLUDED_LANGUAGES = %w(x-test).freeze

    # anonsvn only allows 5 concurrent connections.
    THREAD_COUNT = 5

    def initialize(type, project_name, i18n_path)
      @type = type
      @i18n_path = i18n_path
      @project_name = project_name

      @vcs = Svn.new

      @languages = []
      @templates = []

      validate_instace_variables

      init_repo_url('svn://anonsvn.kde.org/home/kde/')
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

    def languages_queue(excluded = [])
      queue = Queue.new
      languages(excluded).each { |l| queue << l }
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

    private

    # FIXME: not tested
    def self.languages(vcs)
      # Cache this bugger to avoid double lookup for messages and documentation.
      # NOTE: this only is reasonable for as long as all derivaed classes have
      #       the same vcs configuration, so this is potentially dangerous.
      @languages ||= vcs.cat('subdirs').split($RS)
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
        return url_l10n_dir_lts
      when Origin::TRUNK_KDE4, Origin::STABLE_KDE4
        return 'l10n-kde4'
      end
      # FIXME: move the concept of origins to project and make an Array
      # Then blanket assert the type validity in #init
      raise "Unknown l10n type #{type}"
    end

    # LTS is special in that they are about as generic as a hardcoded hardon.
    # Unless we can manually map the LTS origin to a directory it is unreleaseable
    # as we effectively do not know what LTS means for the given product.
    # Since we have no access to higher level data this is derived from i18n_path.
    def url_l10n_dir_lts
      return 'l10n-kf5-plasma-lts' if i18n_path == 'kde-workspace'
      raise "Unknown lts type for path #{i18n_path}."
    end

    def validate_instace_variables
      raise 'type must not be nil' unless @type
      raise 'i18n_path must not be nil' unless @i18n_path
      raise 'project_name must not be nil' unless @project_name
    end
  end
end
