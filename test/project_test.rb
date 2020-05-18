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

def j(*args)
  JSON.generate(*args)
end

def default_i18n
  { stable: nil, stableKF5: nil, trunk: nil, trunkKF5: 'master', component: 'default' }
end

def stub_projects_single(url)
  path = url.gsub('https://projects.kde.org/api/v1/projects/', '')
  stub_request(:get, url).to_return(body: j([path]))
end

def git_stubs
  # Do not let us hit live repos.
  # We do repo ls-remote to check the repo exists on invent.kde.org
  ReleaseMe::Git.any_instance.expects(:run).never

  # Pretend everything exists on invent
  success_status = mock()
  success_status.responds_like_instance_of(Process::Status)
  success_status.stubs(:success?).returns(true)
  ReleaseMe::Git.any_instance.stubs(:run).with do |args|
    next false unless args.include?('ls-remote')
    true
  end.returns(['', success_status])
end

# FIXME: this should go somewhere central or into a class. having a meth in global scope sucks
def stub_api
  git_stubs

  stub_request(:get, 'https://projects.kde.org/api/v1/projects/extragear/utils')
    .to_return(body: JSON.generate(%w[extragear/utils/yakuake
                                      extragear/utils/krusader
                                      extragear/utils/krecipes]))

  # Invalid.
  stub_request(:get, 'https://projects.kde.org/api/v1/projects/kitten')
    .to_return(status: 404)
  stub_request(:get, 'https://projects.kde.org/api/v1/find?id=kitten')
    .to_return(status: 404)
  stub_request(:get, 'https://projects.kde.org/api/v1/projects/utils')
    .to_return(status: 404)
  stub_request(:get, 'https://projects.kde.org/api/v1/find?id=utils')
    .to_return(status: 404)

  stub_request(:get, 'https://projects.kde.org/api/v1/projects/yakuake')
    .to_return(status: 404)
  stub_request(:get, 'https://projects.kde.org/api/v1/find?id=yakuake')
    .to_return(body: j(%w[extragear/utils/yakuake]))

  stub_request(:get, 'https://projects.kde.org/api/v1/project/networkmanager-qt')
    .to_return(status: 404)
  stub_request(:get, 'https://projects.kde.org/api/v1/find?id=networkmanager-qt')
    .to_return(body: j(%w[frameworks/networkmanager-qt]))

  stub_request(:get, 'https://projects.kde.org/api/v1/projects/ktp-contact-runner')
    .to_return(status: 404)
  stub_request(:get, 'https://projects.kde.org/api/v1/find?id=ktp-contact-runner')
    .to_return(body: j(%w[kde/kdenetwork/ktp-contact-runner]))

  stub_request(:get, 'https://projects.kde.org/api/v1/projects/extragear')
    .to_return(body: j(%w[extragear/utils/yakuake
                          extragear/utils/krusader
                          extragear/utils/krecipes
                          extragear/network/telepathy/ktp1
                          extragear/network/telepathy/ktp2]))

  stub_request(:get, 'https://projects.kde.org/api/v1/projects/extragear/network/telepathy')
    .to_return(body: j(%w[extragear/network/telepathy/ktp1
                          extragear/network/telepathy/ktp2]))

  stub_projects_single('https://projects.kde.org/api/v1/projects/kde/kdegraphics/libs/libksane')
  stub_projects_single('https://projects.kde.org/api/v1/projects/extragear/network/telepathy/ktp1')
  stub_projects_single('https://projects.kde.org/api/v1/projects/extragear/network/telepathy/ktp2')
  stub_projects_single('https://projects.kde.org/api/v1/projects/networkmanager-qt')
  stub_projects_single('https://projects.kde.org/api/v1/projects/extragear/utils/yakuake')

  # By Project Path
  stub_request(:get, 'https://projects.kde.org/api/v1/project/extragear/utils/yakuake')
    .to_return(body: j(path: 'extragear/utils/yakuake',
                       repo: 'yakuake',
                       i18n: { stable: nil, stableKF5: 'notmaster', trunk: nil,
                               trunkKF5: 'master', component: 'extragear-utils' }))

  stub_request(:get, 'https://projects.kde.org/api/v1/project/extragear/utils/krusader')
    .to_return(body: j(path: 'extragear/utils/krusader',
                       repo: 'krusader',
                       i18n: default_i18n))

  stub_request(:get, 'https://projects.kde.org/api/v1/project/extragear/utils/krecipes')
    .to_return(body: j(path: 'extragear/utils/krecipes',
                       repo: 'krecipes',
                       i18n: default_i18n))

  stub_request(:get, 'https://projects.kde.org/api/v1/project/extragear/network/telepathy/ktp1')
    .to_return(body: j(path: 'extragear/network/telepathy/ktp1',
                       repo: 'ktp1',
                       i18n: default_i18n))

  stub_request(:get, 'https://projects.kde.org/api/v1/project/extragear/network/telepathy/ktp2')
    .to_return(body: j(path: 'extragear/network/telepathy/ktp2',
                       repo: 'ktp2',
                       i18n: default_i18n))

  stub_request(:get, 'https://projects.kde.org/api/v1/project/kde/kdenetwork/ktp-contact-runner')
    .to_return(body: j(path: 'kde/kdenetwork/ktp-contact-runner',
                       repo: 'ktp-contact-runner',
                       i18n: default_i18n))

  stub_request(:get, 'https://projects.kde.org/api/v1/project/frameworks/networkmanager-qt')
    .to_return(body: j(path: 'frameworks/networkmanager-qt',
                       repo: 'networkmanager-qt',
                       i18n: default_i18n))

  # By Repo
  stub_request(:get, 'https://projects.kde.org/api/v1/repo/kfilemetadata')
    .to_return(body: j(path: 'frameworks/kfilemetadata',
                       repo: 'kfilemetadata',
                       i18n: default_i18n))
end

class TestProjectResolver < Testme
  def setup
    stub_api
  end

  def assert_valid_project(project_array, expected_identifier)
    refute_nil(project_array)
    assert_equal(project_array.size, 1)
    assert_equal(project_array[0].identifier, expected_identifier)
  end

  def test_real_project
    pr = ReleaseMe::Project.from_find('yakuake')
    assert_valid_project(pr, 'yakuake')
  end

  def test_xpath
    # deprecated not used elsewhere
    pr = ReleaseMe::Project.from_xpath('yakuake')
    assert_valid_project(pr, 'yakuake')
  end

  def test_module_as_project
    pr = ReleaseMe::Project.from_find('networkmanager-qt')
    assert_valid_project(pr, 'networkmanager-qt')
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
end

class TestProjectConfig < Testme
  def setup
    stub_api
  end

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

  def test_plasma_lts
    ReleaseMe::Project.class_variable_set(:@@configdir, data('projects/'))
    projects = ReleaseMe::Project.from_find('yakuake')
    assert_equal(projects.size, 1)
    pr = projects.shift
    assert_equal(pr.plasma_lts, 'Plasma/5.8')
  end
end

class TestProject < Testme
  def setup
    stub_api
  end

  def teardown
  end

  def test_manual_construction_fail
    assert_raises do
      # Refuse to new because we need all arguments.
      ReleaseMe::Project.new(identifier: 'a', vcs: nil)
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
    pr = ReleaseMe::Project.new(**data)
    refute_nil(pr)
    assert_equal(pr.identifier, data[:identifier])
    assert_equal(pr.vcs, data[:vcs])
    assert_equal(pr.i18n_trunk, data[:i18n_trunk])
    assert_equal(pr.i18n_stable, data[:i18n_stable])
    assert_equal(pr.i18n_path, data[:i18n_path])
  end

  def test_resolve_valid
    projects = ReleaseMe::Project.from_find('yakuake')
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
    projects = ReleaseMe::Project.from_find('ktp-contact-runner')
    assert_equal(1, projects.size)
    pr = projects.shift
    assert_equal('ktp-contact-runner', pr.identifier)
  end

  def test_resolve_invalid
    projects = ReleaseMe::Project.from_find('kitten')
    assert_equal(projects, [])
  end

  def test_vcs
    projects = ReleaseMe::Project.from_find('yakuake')
    assert_equal(projects.size, 1)
    pr = projects.shift
    vcs = pr.vcs
    assert_equal('git@invent.kde.org:yakuake', vcs.repository)
    assert_nil(vcs.branch) # project on its own should not set a branch
  end

  def test_from_repo_url
    # Mock Git internals to make this repo default to git.kde.org instead
    # of invent.kde.org by pretending the ls-remote fails.
    fail_status = mock()
    fail_status.responds_like_instance_of(Process::Status)
    fail_status.stubs(:success?).returns(false)
    ReleaseMe::Git.any_instance.stubs(:run).with do |args|
      next false unless args.include?('ls-remote')
      next false unless args.include?('git@invent.kde.org:kde/kfilemetadata')
      true
    end.returns(['', fail_status])

    projects = ReleaseMe::Project.from_repo_url('git://anongit.kde.org/kfilemetadata')
    assert_equal(1, projects.size)
    pr = projects.shift
    assert_equal('kfilemetadata', pr.identifier)
    assert_equal('git@invent.kde.org:kfilemetadata', pr.vcs.repository)
  end
end
