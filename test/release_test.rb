# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2011-2022 Harald Sitter <sitter@kde.org>

require_relative 'lib/testme'

require_relative '../lib/releaseme/git'
require_relative '../lib/releaseme/origin'
require_relative '../lib/releaseme/project'
require_relative '../lib/releaseme/release'

class TestRelease < Testme
  module Silencer
    module_function

    def run(cmd)
      `#{cmd} 2>&1`
    end
  end

  attr_reader :remotedir

  def `(other)
    Silencer.run(other)
  end

  def setup_repo_content
    `git clone #{@remotedir} clone`
    Dir.chdir('clone') do
      File.write('file', 'content')
      `git add file`
      `git commit -a -m 'import'`
      `git push origin master`
    end
  ensure
    FileUtils.rm_rf('clone')
  end

  # FIXME: this needs putting in a module or something for reuse here, in source
  # and in git
  def setup
    # Create a test remote
    Dir.mkdir('remote')
    Dir.chdir('remote') do
      `git init --bare .`
    end
    @remotedir = "#{Dir.pwd}/remote"

    setup_repo_content

    stub_request(:get, %r{https://invent.kde.org/api/v4/projects/.+/pipelines\?page=0&ref=master})
      .to_return(body: <<~JSON)
        [
          {"id":209072,"iid":140,"project_id":2823,"sha":"79e4a8166394efcb772eea55cab871c37e239231","ref":"master","status":"success","source":"push","created_at":"2022-07-25T23:46:53.398Z","updated_at":"2022-07-25T23:47:36.958Z","web_url":"https://invent.kde.org/utilities/yakuake/-/pipelines/209072"}
        ]
      JSON
    WebMock.enable!

    # Teardown happens automatically when the @tmpdir is torn down
  end

  def teardown
    WebMock.reset!
  end

  def new_test_release
    data = {
      :identifier => 'clone',
      :vcs => ReleaseMe::Git.new,
      :i18n_trunk => 'master',
      :i18n_stable => 'master',
      :i18n_path => ''
    }
    project = ReleaseMe::Project.new(**data)
    project.vcs.repository = @remotedir

    r = ReleaseMe::Release.new(project, :trunk, '1.0')

    refute_nil(r)
    assert_equal(project, r.project)
    assert_equal(:trunk, r.origin)
    assert_equal('1.0', r.version)
    assert_equal('clone-1.0', r.source.target)

    r
  end

  def test_init
    new_test_release
  end

  def test_get_archive_cleanup
    r = new_test_release

    @dir = r.source.target
    refute_path_exist(@dir)
    r.get
    assert_path_exist(@dir)
    assert_path_exist("#{@dir}/file")

    refute_path_exist("#{@dir}.tar.xz")
    r.archive
    assert_path_exist("#{@dir}.tar.xz")
    assert_path_exist("#{@dir}.tar.xz.sig")

    assert_path_exist(@dir)
    r.source.cleanup
    refute_path_exist(@dir)
  end

  def test_kde4_origin
    data = {
      :identifier => 'clone',
      :vcs => ReleaseMe::Git.new,
      :i18n_trunk => 'master',
      :i18n_stable => 'master',
      :i18n_path => ''
    }
    project = ReleaseMe::Project.new(**data)
    project.vcs.repository = @remotedir

    assert_raises do
      ReleaseMe::Release.new(project, Project::TRUNK_KDE4, '1.0')
    end
  end

  def test_ci_check_all_good
    # For now we can stub on a HTTP level, should the Jenkins classes become
    # too complex it will be better to moch the objects themself. Moddelling
    # the http interaction litters a lot.

    stub_request(:get, %r{https://invent.kde.org/api/v4/projects/.+/pipelines\?page=0&ref=master})
      .to_return(body: <<~JSON)
        [
          {"id":209072,"iid":140,"project_id":2823,"sha":"79e4a8166394efcb772eea55cab871c37e239231","ref":"master","status":"success","source":"push","created_at":"2022-07-25T23:46:53.398Z","updated_at":"2022-07-25T23:47:36.958Z","web_url":"https://invent.kde.org/utilities/yakuake/-/pipelines/209072"}
        ]
      JSON

    data = {
      identifier: 'clone',
      vcs: ReleaseMe::Git.new,
      i18n_trunk: 'master',
      i18n_stable: 'master',
      i18n_path: ''
    }
    project = ReleaseMe::Project.new(**data)
    project.vcs.repository = @remotedir

    ReleaseMe::Release.new(project, ReleaseMe::Origin::TRUNK, '1.0').get
  end

  def test_ci_check_one_building_one_shitty
    # For now we can stub on a HTTP level, should the Jenkins classes become
    # too complex it will be better to moch the objects themself. Moddelling
    # the http interaction litters a lot.

    stub_request(:get, %r{https://invent.kde.org/api/v4/projects/.+/pipelines\?page=0&ref=master})
      .to_return(body: <<~JSON)
        [
          {"id":210853,"iid":141,"project_id":2823,"sha":"ad9819d56839ba0380fafad97d2ca043f9424b59","ref":"master","status":"pending","source":"push","created_at":"2022-07-31T01:53:32.240Z","updated_at":"2022-07-31T01:53:32.240Z","web_url":"https://invent.kde.org/utilities/yakuake/-/pipelines/210853"},
          {"id":210853,"iid":141,"project_id":2823,"sha":"ad9819d56839ba0380fafad97d2ca043f9424b59","ref":"master","status":"failed","source":"push","created_at":"2022-07-31T01:53:32.240Z","updated_at":"2022-07-31T01:53:32.240Z","web_url":"https://invent.kde.org/utilities/yakuake/-/pipelines/210853"}
        ]
      JSON

    data = {
      identifier: 'clone',
      vcs: ReleaseMe::Git.new,
      i18n_trunk: 'master',
      i18n_stable: 'master',
      i18n_path: ''
    }
    project = ReleaseMe::Project.new(**data)
    project.vcs.repository = @remotedir

    # Release.rb will call abort once we tell it to not ignore the shitty jobs.
    # We intercept this and instead raise a sytemcallerror to verify that this
    # is in fact what occurred.
    ReleaseMe::Silencer.expects(:shutup?).returns(false).at_least_once
    ReleaseMe::Release.any_instance.expects(:abort).raises(SystemCallError.new(''))
    ReleaseMe::Release.any_instance.expects(:gets).returns("n\n")
    assert_raises SystemCallError do
      ReleaseMe::Release.new(project, ReleaseMe::Origin::TRUNK, '1.0').get
    end
    refute_path_exist('clone-1.0')
  end

  def test_help
    data = {
      identifier: 'clone',
      vcs: ReleaseMe::Git.new,
      i18n_trunk: 'master',
      i18n_stable: 'master',
      i18n_path: ''
    }
    project = ReleaseMe::Project.new(**data)
    project.vcs.repository = @remotedir

    r = ReleaseMe::Release.new(project, :trunk, '1.0')
    r.get
    r.archive

    # We do not particularly care about the output at this time. What matters
    # is that it passes.
    r.help
  end

  def test_phonon_compat_mapping
    data = {
      identifier: 'phonon-vlc',
      vcs: ReleaseMe::Git.new,
      i18n_trunk: 'master',
      i18n_stable: 'master',
      i18n_path: ''
    }
    project = ReleaseMe::Project.new(**data)
    project.vcs.repository = @remotedir

    r = ReleaseMe::Release.new(project, :trunk, '1.0')
    assert_equal('phonon-backend-vlc-1.0', r.source.target)
  end

  def test_sysadmin_ticket
    FileUtils.touch('tar')
    FileUtils.touch('sig')
    release = new_test_release
    release.send(:sysadmin_ticket, 'tar', 'sig')
  end
end
