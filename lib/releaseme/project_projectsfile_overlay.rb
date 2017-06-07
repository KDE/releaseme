#--
# Copyright (C) 2017 Harald Sitter <sitter@kde.org>
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

require_relative 'git'
require_relative 'projects_api'

module ReleaseMe
  # Opt-in api overlay replacing the XML projectsfile. Experimental
  module ProjectProjectsfileOverlay
    # Class methods.
    module ClassMethods
      ##
      # call-seq:
      #  project.resolve_attributes!() -> true or false
      #
      # Resolve project attributes by hand. All three REXML elements must be set
      # before this function will do anything useful. Also see set_elements().
      #--
      # FIXME: needs tests
      #++
      def resolve_attributes!
        # FIXME: maybe should raise?
        return false if @project_element.nil?

        # TODO: projects have an 'active' flag, if that is false we likely
        #        should print a warnign and ask whether we really should continue

        doc = ProjectsFile.xml_doc

        @identifier = @project_element.attribute('identifier').to_s

        # Resolve git url.
        @vcs = nil
        urls = doc.root.get_elements("#{@project_element.xpath}/repo/url")
        urls.each do |url|
          # FIXME: we need a way to switch between RO and RW as
          # a) distros like to use it so they may not have RW access
          # b) we need RW access for tagme, so tagme needs a way to explicitly
          #    request the RW repo url rather than the RO one...
          unless url.attribute('access').to_s == 'read+write' &&
                 url.attribute('protocol').to_s == 'ssh'
            next
          end
          @vcs = Git.new
          @vcs.repository = url.text
        end

        branches = doc.root.get_elements("#{@project_element.xpath}/repo/branch")
        branches.each do |branch|
          i18n = branch.attribute('i18n').to_s
          text = branch.text
          next if i18n.nil? || i18n.empty?
          next if text.nil? || text.empty? || text == 'none'
          if i18n == 'trunk_kf5'
            @i18n_trunk = text
          elsif i18n == 'stable_kf5'
            @i18n_stable = text
          end
        end

        return false unless @vcs

        # Figure out which i18n path to use.
        @project_element.elements.each do |e|
          next unless e.name == 'path'
          path = e.text
          raise 'unknown path' unless path
          @i18n_path = reduce_i18n_path(path)
        end
        return false unless @i18n_path

        # LTS branch only used for Plasma so unless it's set in a config file
        # just use stable branch
        if @i18n_path == 'kde-workspace'
          @i18n_lts = plasma_lts
        else
          @i18n_lts == @i18n_stable
        end

        true
      end

      def reduce_i18n_path(path)
        # Break the full project path down into parts and mangle them until
        # we get the path under which this project would appear in SVN.
        parts = path.split('/')
        drop_limit = 2

        # Start off with stripping the leading kde/.
        if parts[0] == 'kde' && parts[1] != 'workspace'
          # Everything but kde/workspace is flattend without the kde part.
          # kde/workspace on the other hand is kde-workspace.
          # So, for everything but workspace, drop the kde part.
          #   [kde,workspace] => same
          #   [kde,kdepim-runtime] => [kdepim-runtime]
          #   [kde,kdegraphics,libs] => [kdegraphics,libs]
          parts.shift
          # Shrink the drop limit. When we dropped kde/ we'll effecitvely have
          # removed the original assumption of there being two elements to join
          # as we already removed the first element. Workspace is the best example
          # of this fact as it is kde-workspace even though pim isn't kde-pim.
          # That is also why it needs special treatment.
          drop_limit = 1
        end

        # Ditch last part as that is our name. But only if we in fact have more
        # parts. Otherwise the last part is the i18n_path of a flat
        # component. e.g. kdepim-runtime is a component AND the project.
        parts.pop if parts.size > 1

        # Reduce the path down to 2-1 parts at the most to strip subprojects
        #   [calligra] => same
        #   [frameworks] => same
        #   [workspace] => same
        #   [kdepim-runtime] => same
        #   [kdegraphics,libs] => [kdegraphics] (drop limit was 1)
        #   [extragear,utils,telepathy] => [extragear,utils] (drop limit was 2)
        parts.pop while parts.size > drop_limit

        # The remainder is between 1 and 2 parts long which we'll join to get
        # the i18n path.
        #   [calligra] => 'calligra'
        #   [frameworks] => 'frameworks'
        #   [kde,workspace] => 'kde-workspace'
        #   [kdepim-runtime] => 'kdepim-runtime'
        #   [kdegraphics] => 'kdegraphics'
        #   [extragear,utils] => 'extragear-utils'
        parts.join('-')
      end

      # @return [Array<Project>] can be empty
      def from_xpath(project_id)
        release_projects = []

        # Cleanup project_id. Mustn't have trailing slashes or a
        # wildcard asterisk. All not supported and in fact screwing with the
        # parser.
        project_id = project_id.chomp('*') while project_id.end_with?('*')
        project_id = project_id.chomp('/') while project_id.end_with?('/')

        %w(project module component).each do |element_type|
          search_string = "//#{element_type}[@identifier]"
          release_projects += find_suitable_projects(search_string, project_id)
        end

        release_projects
      end

      # @param url [String] find all Projects associated with this repo url.
      # @return [Array<Project>] can be empty
      def from_repo_url(url)
        # XPath is like a knife in the eye.
        # This finds all url nodes, with any ancestry, where their text is
        # exactly equal to the requested url. Of those it then selects the
        # ancestors of type project (there should only be one of those one hopes).
        element = url_elements.fetch(url, nil)
        return [] unless element
        [Project.new(project_element: element).tap(&:resolve_attributes!)]
      end

      private

      # Cache hash of url=>xml_element.
      def url_elements
        @hash ||= begin
          r = {}
          ProjectsFile.xml_doc.root.get_elements('//repo/url').each do |element|
            # Can't xpath to ancestor::project[1] as some crap is a module. WTF.
            projects = element.get_elements('../../').to_a
            raise "multiple parents :( #{projects}" unless projects.size <= 1
            next if projects.size.zero?
            r[element.text] = projects[0]
          end
          r
        end
      end

      def element_matches_path?(element, path)
        element.elements.each do |e|
          if e.name == 'path' && (e.text == path || e.text.start_with?(path))
            return true
          end
        end
        false
      end

      def find_suitable_projects(xpath, project_id)
        ret = []
        ProjectsFile.xml_doc.root.get_elements(xpath).each do |element|
          suitable = false
          if element.attribute('identifier').to_s == project_id ||
             element_matches_path?(element, project_id)
            suitable = true
          end
          next unless suitable
          has_children = false
          # FIXME: do we really need to xpath recursive here?
          element.each_element("/#{element.xpath}/*[@identifier]") do |_|
            has_children = true
            break
          end
          next if has_children
          pr = Project.new(project_element: element)
          pr.resolve_attributes!
          ret << pr
        end
        ret
      end
    end

    def self.prepended(base)
      class << base
        prepend ClassMethods
      end
    end
  end
end
