#--
# Copyright (C) 2014-2017 Harald Sitter <sitter@kde.org>
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

require 'net/http'
require 'rexml/document'
require 'yaml'

require_relative 'git'
require_relative 'projectsfile'
require_relative 'project_api_overlay'
require_relative 'project_projectsfile_overlay'

module ReleaseMe
  class Project
    if ENV.fetch('RELEASEME_PROJECTSFILE', false)
      prepend ProjectProjectsfileOverlay
    else
      prepend ProjectAPIOverlay
    end

    @@configdir = "#{File.dirname(File.dirname(File.expand_path(__dir__)))}/projects/"

    # Project identifer found. nil if not resolved.
    attr_reader :identifier
    # VCS to use for this project
    attr_reader :vcs
    # Branch used for i18n trunk
    attr_reader :i18n_trunk
    # Branch used for i18n stable
    attr_reader :i18n_stable
    # Branch used for i18n lts (same as stable except for Plasma)
    attr_reader :i18n_lts
    # Path used for i18n.
    attr_reader :i18n_path

    # Creates a new Project. Identifier can be nil but must be set manually
    # before calling resolve.
    def initialize(project_element: nil,
                   identifier: nil,
                   vcs: nil,
                   i18n_trunk: nil,
                   i18n_stable: nil,
                   i18n_lts: nil,
                   i18n_path: nil)
      unless project_element || (identifier && vcs)
        raise 'Project construction either needs to happen with a' \
              ' project_element or all other values being !nil'
      end
      @identifier = identifier
      @vcs = vcs
      @i18n_trunk = i18n_trunk
      @i18n_stable = i18n_stable
      @i18n_lts = i18n_lts
      @i18n_path = i18n_path
      @project_element = project_element
    end

    # Constructs a Project instance from the definition placed in
    # projects/project_name.yml
    # @param project_name name of the yml file to look for. This is not reflected
    #   in the actual Project.identifier, just like the original xpath when using
    #   from_xpath.
    # @return Project never empty, raises exceptions when something goes wrong
    # @raise RuntimeError on every occasion ever. Unless something goes wrong deep
    #        inside.
    def self.from_config(project_name)
      ymlfile = "#{@@configdir}/#{project_name}.yml"
      unless File.exist?(ymlfile)
        raise "Project file for #{project_name} not found [#{ymlfile}]."
      end

      data = YAML.load(File.read(ymlfile))
      data = data.inject({}) do |tmphsh, (key, value)|
        key = key.downcase.to_sym
        if key == :vcs
          raise 'Vcs configuration has no type key.' unless value.key?('type')
          begin
            vcs_type = value.delete('type')
            require_relative vcs_type.downcase.to_s
            value = ReleaseMe.const_get(vcs_type).from_hash(value)
          rescue LoadError, RuntimeError => e
            raise "Failed to resolve the Vcs values #{value} -->\n #{e}"
          end
        end
        tmphsh[key] = value
        next tmphsh
      end

      Project.new(**data)
    end

    def plasma_lts
      self.class.plasma_lts
    end

    class << self
      def plasma_lts
        ymlfile = "#{@@configdir}/plasma.yml"
        unless File.exist?(ymlfile)
          raise "Project file for Plasma not found [#{ymlfile}]."
        end

        data = YAML.load_file(ymlfile)
        data['i18n_lts']
      end
    end
  end
end
