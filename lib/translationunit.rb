#--
# Copyright (C) 2007-2015 Harald Sitter <sitter@kde.org>
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

require 'fileutils'

require_relative 'cmakeeditor'
require_relative 'source'
require_relative 'svn'

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

  # Type identifiers
  TRUNK  = :trunk
  STABLE = :stable

  attr_reader :project_name

  def initialize(type, project_name, i18n_path)
    if type.nil?
      fail 'type must not be nil'
    else
      @type = type
    end

    if i18n_path.nil?
      fail 'i18n_path must not be nil'
    else
      @i18n_path = i18n_path
    end

    if project_name.nil?
      fail 'project_name must not be nil'
    else
      @project_name = project_name
    end

    @vcs = Svn.new

    @languages = []
    @templates = []

    init_repo_url('svn://anonsvn.kde.org/home/kde/')
  end

  # FIXME: this name seems a bit meh
  def init_repo_url(base_url)
    repo_url = base_url
    repo_url += '/' unless repo_url.end_with?('/')
    # FIXME: outsource into own function
    if type == TRUNK
      repo_url += 'trunk/'
    else
      repo_url += 'branches/stable/'
    end
    repo_url += '/l10n-kf5/'

    @vcs.repository = repo_url
  end

  def vcs_l10n_path(lang)
    fail 'todo'
  end

  def get(source_dir)
    fail 'todo'
  end
end
