#--
# Copyright (C) 2014-2015 Harald Sitter <apachelogger@ubuntu.com>
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

require "fileutils"
require "test/unit"

require_relative "../lib/project"
require_relative "../lib/vcs"

class TestProjectResolver < Test::Unit::TestCase
    def setup
        # Project uses ProjectsFile to read data, so we need to make sure it
        # uses our dummy file.
        ProjectsFile.xml_path = Dir.pwd + '/data/kde_projects_advanced.xml'
        ProjectsFile.load!
    end

    def assert_valid_project(project_array, expected_identifier)
        assert_not_nil(project_array)
        assert_equal(project_array.size, 1)
        assert_equal(project_array[0].identifier, expected_identifier)
    end

    def test_real_project
        pr = Project::from_xpath("yakuake")
        assert_valid_project(pr, "yakuake")
    end

    def test_real_project_with_full_path
        pr = Project::from_xpath("extragear/utils/yakuake")
        assert_valid_project(pr, "yakuake")
    end

    def test_module_as_project
        pr = Project::from_xpath("networkmanager-qt")
        assert_valid_project(pr, "networkmanager-qt")
    end

    def test_component_as_project
        pr = Project::from_xpath("calligra")
        assert_valid_project(pr, "calligra")
    end

    ####### nested resolution

    def assert_valid_extragear_utils_array(project_array)
        assert_not_nil(project_array)
        matches = %w(yakuake krusader krecipes)
        assert_equal(project_array.size, matches.size)
        project_array.each do | project |
            matches.delete(project.identifier)
        end
        assert(matches.empty?, "One or more sub-projects did not get resolved correctly")
    end

    def test_module
        pr = Project::from_xpath("utils")
        assert_valid_extragear_utils_array(pr)
    end

    def test_module_with_full_path
        pr = Project::from_xpath("extragear/utils")
        assert_valid_extragear_utils_array(pr)
    end

    def test_component
        pr = Project::from_xpath("extragear")
        assert_valid_extragear_utils_array(pr)
    end
end

class TestProject < Test::Unit::TestCase
    def setup
        # Project uses ProjectsFile to read data, so we need to make sure it
        # uses our dummy file.
        ProjectsFile.xml_path = Dir.pwd + '/data/kde_projects.xml'
        ProjectsFile.load!
    end

    def teardown
    end

    def test_manual_construction_fail
        assert_raise do
            # Refuse to new because we need all arguments.
            pr = Project.new(identifier: 'a', vcs: nil)
        end
    end

    def test_manual_construction_success
        data = {
            :identifier => 'yakuake',
            :vcs => Vcs.new,
            :i18n_trunk => 'master',
            :i18n_stable => 'master',
            :i18n_path => 'extragear-utils'
        }
        assert_nothing_raised do
            Project.new(data)
        end
        pr = Project.new(data)
        assert_not_nil(pr)
        assert_equal(pr.identifier, data[:identifier])
        assert_equal(pr.vcs, data[:vcs])
        assert_equal(pr.i18n_trunk, data[:i18n_trunk])
        assert_equal(pr.i18n_stable, data[:i18n_stable])
        assert_equal(pr.i18n_path, data[:i18n_path])
    end

    def test_resolve_valid
        projects = Project::from_xpath('yakuake')
        assert_equal(projects.size, 1)
        pr = projects.shift
        assert_equal(pr.identifier, 'yakuake')
        assert_equal(pr.i18n_trunk, 'master')
        assert_equal(pr.i18n_stable, 'notmaster')
        assert_equal(pr.i18n_path, 'extragear-utils')
    end

    def test_resolve_invalid
        projects = Project::from_xpath('kitten')
        assert_equal(projects, nil)
    end

    def test_vcs
        projects = Project::from_xpath('yakuake')
        assert_equal(projects.size, 1)
        pr = projects.shift
        vcs = pr.vcs
        assert_equal(vcs.repository, 'git@git.kde.org:yakuake')
        assert_equal(vcs.branch, nil) # project on its own should not set a branch
    end
end
