#--
# Copyright (C) 2014-2015 Harald Sitter <sitter@kde.org>
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

require_relative 'lib/testme'
require_relative '../lib/releaseme/project'
require_relative '../lib/releaseme/vcs'

class TestProjectResolver < Testme
  def setup
    # Project uses ProjectsFile to read data, so we need to make sure it
    # uses our dummy file.
    ReleaseMe::ProjectsFile.xml_path = data('kde_projects_advanced.xml')
    ReleaseMe::ProjectsFile.load!
  end

  def assert_valid_project(project_array, expected_identifier)
    refute_nil(project_array)
    assert_equal(project_array.size, 1)
    assert_equal(project_array[0].identifier, expected_identifier)
  end

  def test_real_project
    pr = ReleaseMe::Project.from_xpath('yakuake')
    assert_valid_project(pr, 'yakuake')
  end

  def test_real_project_with_full_path
    pr = ReleaseMe::Project.from_xpath('extragear/utils/yakuake')
    assert_valid_project(pr, 'yakuake')
  end

  def test_module_as_project
    pr = ReleaseMe::Project.from_xpath('networkmanager-qt')
    assert_valid_project(pr, 'networkmanager-qt')
  end

  def test_component_as_project
    pr = ReleaseMe::Project.from_xpath('calligra')
    assert_valid_project(pr, 'calligra')
  end

  ####

  def assert_valid_array(project_array, matches)
    refute_nil(project_array)
    assert_equal(matches.size, project_array.size)
    project_array.each do |project|
      matches.delete(project.identifier)
    end
    assert(matches.empty?, "One or more sub-projects did not get resolved correctly: #{matches}")
  end

  ####### nested resolution

  def assert_valid_extragear_utils_array(project_array)
    assert_valid_array(project_array, %w[yakuake krusader krecipes])
  end

  def test_module
    pr = ReleaseMe::Project.from_xpath('utils')
    assert_equal([], pr)
  end

  def test_module_with_full_path
    pr = ReleaseMe::Project.from_xpath('extragear/utils')
    assert_valid_extragear_utils_array(pr)
  end

  ####### super nested resolution

  def assert_valid_telepathy_array(project_array)
    assert_valid_array(project_array, %w[ktp1 ktp2])
  end

  def test_project_with_subprojects
    pr = ReleaseMe::Project.from_xpath('extragear/network/telepathy')
    assert_valid_telepathy_array(pr)

    pr = ReleaseMe::Project.from_xpath('extragear/network/telepathy/ktp1')
    refute_nil(pr)
    assert_equal('ktp1', pr[0].identifier)
  end

  def assert_valid_extragear_array(project_array)
    assert_valid_array(project_array, %w[yakuake krusader krecipes ktp1 ktp2])
  end

  def test_component
    pr = ReleaseMe::Project.from_xpath('extragear')
    assert_valid_extragear_array(pr)
  end
end

class TestProjectConfig < Testme
  def test_invalid_name
    name = 'kittens'
    assert_raises do
      ReleaseMe::Project.from_config(name)
    end
  end

  def test_construction_git
    ReleaseMe::Project.class_variable_set(:@@configdir, data('projects/'))
    name = 'valid'
    pr = ReleaseMe::Project.from_config(name)
    refute_nil(pr)
    assert_equal('yakuake', pr.identifier)
    assert_equal('git://anongit.kde.org/yakuake', pr.vcs.repository)
    assert_equal('master', pr.i18n_trunk)
    assert_equal('notmaster', pr.i18n_stable)
    assert_nil(pr.i18n_lts)
    assert_equal('extragear-utils', pr.i18n_path)
  end

  def test_valid_svn
    ReleaseMe::Project.class_variable_set(:@@configdir, data('projects/'))
    name = 'valid-svn'
    pr = ReleaseMe::Project.from_config(name)
    refute_nil(pr)
    assert_equal('svn://anonsvn.kde.org/home', pr.vcs.repository)
  end

  def test_invalid_vcs
    ReleaseMe::Project.class_variable_set(:@@configdir, data('projects/'))
    name = 'invalid-vcs'
    assert_raises NoMethodError do
      ReleaseMe::Project.from_config(name)
    end
  end

  def test_invalid_vcs_type
    ReleaseMe::Project.class_variable_set(:@@configdir, data('projects/'))
    name = 'invalid-vcs-type'
    assert_raises RuntimeError do
      ReleaseMe::Project.from_config(name)
    end
  end
end

class TestProject < Testme
  def setup
    # Project uses ProjectsFile to read data, so we need to make sure it
    # uses our dummy file.
    ReleaseMe::ProjectsFile.xml_path = data('kde_projects.xml')
    ReleaseMe::ProjectsFile.load!
  end

  def teardown
  end

  def test_manual_construction_fail
    assert_raises do
      # Refuse to new because we need all arguments.
      pr = ReleaseMe::Project.new(identifier: 'a', vcs: nil)
    end
  end

  def test_manual_construction_success
    data = {
      :identifier => 'yakuake',
      :vcs => ReleaseMe::Vcs.new,
      :i18n_trunk => 'master',
      :i18n_stable => 'master',
      :i18n_path => 'extragear-utils'
    }
    ReleaseMe::Project.new(data)
    pr = ReleaseMe::Project.new(data)
    refute_nil(pr)
    assert_equal(pr.identifier, data[:identifier])
    assert_equal(pr.vcs, data[:vcs])
    assert_equal(pr.i18n_trunk, data[:i18n_trunk])
    assert_equal(pr.i18n_stable, data[:i18n_stable])
    assert_equal(pr.i18n_path, data[:i18n_path])
  end

  def test_resolve_valid
    projects = ReleaseMe::Project.from_xpath('yakuake')
    assert_equal(projects.size, 1)
    pr = projects.shift
    assert_equal('yakuake', pr.identifier)
    assert_equal('master', pr.i18n_trunk)
    assert_equal('notmaster', pr.i18n_stable)
    assert_equal('extragear-utils', pr.i18n_path)
  end

  def test_resolve_valid_i18n_path_with_sub_project
    # ktp things are in extragear/network/telepathy/ktp*, yet their
    # translation path is component-module. Make sure that we get the correct
    # path for this.
    # Other example would be extragear/graphics/libs/kdiagram.
    projects = ReleaseMe::Project.from_xpath('ktp-contact-runner')
    assert_equal(1, projects.size)
    pr = projects.shift
    assert_equal('ktp-contact-runner', pr.identifier)
    assert_equal('extragear-utils', pr.i18n_path)
  end

  def assert_i18n_path(project_name, i18n_path)
    projects = ReleaseMe::Project.from_xpath(project_name)
    assert_equal(1, projects.size)
    pr = projects.shift
    assert_equal(i18n_path, pr.i18n_path)
  end

  def test_resolve_valid_i18n_path_all_garbage_combinations
    assert_i18n_path('ktp-contact-runner', 'extragear-utils')
    assert_i18n_path('kfilemetadata', 'kde-workspace')
    assert_i18n_path('kde/kdenetwork/ktp-common-internal', 'kdenetwork')
  end

  def test_resolve_invalid
    projects = ReleaseMe::Project.from_xpath('kitten')
    assert_equal(projects, [])
  end

  def test_vcs
    projects = ReleaseMe::Project.from_xpath('yakuake')
    assert_equal(projects.size, 1)
    pr = projects.shift
    vcs = pr.vcs
    assert_equal(vcs.repository, 'git@git.kde.org:yakuake')
    assert_nil(vcs.branch) # project on its own should not set a branch
  end

  def test_plasma_lts
    projects = ReleaseMe::Project.from_xpath('yakuake')
    assert_equal(projects.size, 1)
    pr = projects.shift
    assert_equal(pr.plasma_lts, 'Plasma/5.8')
  end

  def test_from_repo_url
    projects = ReleaseMe::Project.from_repo_url('git://anongit.kde.org/kfilemetadata')
    assert_equal(1, projects.size)
    pr = projects.shift
    assert_equal('kfilemetadata', pr.identifier)
    assert_equal('git@git.kde.org:kfilemetadata', pr.vcs.repository)
  end

  def test_flat_project
    # Make sure i18n_path of modules that are also projects get properly
    # constructed.
    # https://bugs.kde.org/show_bug.cgi?id=379164
    projects = ReleaseMe::Project.from_xpath('kde/kdepim-runtime')
    assert_equal(projects.size, 1)
    pr = projects.shift
    assert_equal('kdepim-runtime', pr.i18n_path)
  end

  def test_deep_project
    # Make sure i18n_path of modules that are inside projects on a third level
    # nested get properly constructed.
    # https://bugs.kde.org/show_bug.cgi?id=379161
    projects = ReleaseMe::Project.from_xpath('kde/kdegraphics/libs/libksane')
    assert_equal(projects.size, 1)
    pr = projects.shift
    assert_equal('kdegraphics', pr.i18n_path)
  end

  def test_krita
    # Make sure krita's i18n_path gets properly resolved.
    projects = ReleaseMe::Project.from_xpath('krita')
    assert_equal(projects.size, 1)
    pr = projects.shift
    assert_equal('calligra', pr.i18n_path)
  end
end
