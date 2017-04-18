require_relative 'lib/testme'

require_relative '../lib/releaseme/git'
require_relative '../lib/releaseme/project'
require_relative '../lib/releaseme/release'

require 'mocha/test_unit'

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

    stub_request(:get, 'https://build.kde.org/api/json?tree=jobs%5Bname,url%5D,views%5Bname%5D')
      .to_return(body: JSON.generate(jobs: []))
    WebMock.enable!

    # Disable all SVN nonesense so we don't hit live servers.
    fake_svn = mock('svn')
    fake_svn.stubs(:repository=)
    fake_svn.stubs(:cat).returns('')
    fake_svn.stubs(:list).returns('')
    fake_svn.stubs(:get).returns(true)
    ReleaseMe::Svn.stubs(:new).returns(fake_svn)

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
    project = ReleaseMe::Project.new(data)
    project.vcs.repository = @remotedir

    r = ReleaseMe::Release.new(project, :trunk, '1.0')

    assert_not_nil(r)
    assert_equal(project, r.project)
    assert_equal(:trunk, r.origin)
    assert_equal('1.0', r.version)
    assert_equal('clone-1.0', r.source.target)

    r
  end

  def new_test_release_svn
    data = {
      :identifier => 'clone',
      :vcs => ReleaseMe::Svn.new,
      :i18n_trunk => 'master',
      :i18n_stable => 'master',
      :i18n_path => ''
    }
    project = ReleaseMe::Project.new(data)
    project.vcs.repository = @remotedir
    ReleaseMe::Release.new(project, :trunk, '1.0')
  end

  def test_init
    new_test_release
    new_test_release_svn
  end

  def test_get_archive_cleanup
    r = new_test_release

    @dir = r.source.target
    assert(!File.exist?(@dir))
    r.get
    assert(File.exist?(@dir))
    assert(File.exist?("#{@dir}/file"))

    assert(!File.exist?("#{@dir}.tar.xz"))
    r.archive
    assert(File.exist?("#{@dir}.tar.xz"))
    assert_path_exist("#{@dir}.tar.xz.sig")

    assert(File.exist?(@dir))
    r.source.cleanup
    assert(!File.exist?(@dir))
  end

  def test_kde4_origin
    data = {
      :identifier => 'clone',
      :vcs => ReleaseMe::Git.new,
      :i18n_trunk => 'master',
      :i18n_stable => 'master',
      :i18n_path => ''
    }
    project = ReleaseMe::Project.new(data)
    project.vcs.repository = @remotedir

    assert_raise do
      ReleaseMe::Release.new(project, Project::TRUNK_KDE4, '1.0')
    end
  end

  def test_ci_check_all_good
    # For now we can stub on a HTTP level, should the Jenkins classes become
    # too complex it will be better to moch the objects themself. Moddelling
    # the http interaction litters a lot.

    stub_request(:get, 'https://build.kde.org/api/json?tree=jobs%5Bname,url%5D,views%5Bname%5D')
      .to_return(body: JSON.generate(
        jobs: [
          {
            name: 'clone master kf5-qt5',
            url: 'https://build.kde.org/job/clone/'
          }
        ]
      ))

    stub_request(:get, 'https://build.kde.org/job/clone/lastBuild/api/json')
      .to_return(body: JSON.generate(id: 17))
    stub_request(:get, 'https://build.kde.org/job/clone/lastSuccessfulBuild/api/json')
      .to_return(body: JSON.generate(id: 17))
    stub_request(:get, 'https://build.kde.org/job/clone/lastStableBuild/api/json')
      .to_return(body: JSON.generate(id: 17))
    stub_request(:get, 'https://build.kde.org/job/clone/lastCompletedBuild/api/json')
      .to_return(body: JSON.generate(id: 17))

    data = {
      identifier: 'clone',
      vcs: ReleaseMe::Git.new,
      i18n_trunk: 'master',
      i18n_stable: 'master',
      i18n_path: ''
    }
    project = ReleaseMe::Project.new(data)
    project.vcs.repository = @remotedir

    ReleaseMe::Release.new(project, Origin::TRUNK, '1.0').get
  end

  def test_ci_check_one_building_one_shitty
    # For now we can stub on a HTTP level, should the Jenkins classes become
    # too complex it will be better to moch the objects themself. Moddelling
    # the http interaction litters a lot.

    stub_request(:get, 'https://build.kde.org/api/json?tree=jobs%5Bname,url%5D,views%5Bname%5D')
      .to_return(body: JSON.generate(
        jobs: [
          {
            name: 'clone master kf5-qt5',
            url: 'https://build.kde.org/job/clone/'
          },
          {
            name: 'clone master kf5-qt5-kitten',
            url: 'https://build.kde.org/job/clone2/'
          }
        ]
      ))

    # clone is still building
    stub_request(:get, 'https://build.kde.org/job/clone/api/json')
      .to_return(body: JSON.generate(displayName: 'clone'))
    stub_request(:get, 'https://build.kde.org/job/clone/lastBuild/api/json')
      .to_return(body: JSON.generate(id: 17))
    stub_request(:get, 'https://build.kde.org/job/clone/lastSuccessfulBuild/api/json')
      .to_return(body: JSON.generate(id: 16))
    stub_request(:get, 'https://build.kde.org/job/clone/lastStableBuild/api/json')
      .to_return(body: JSON.generate(id: 16))
    stub_request(:get, 'https://build.kde.org/job/clone/lastCompletedBuild/api/json')
      .to_return(body: JSON.generate(id: 16))

    # clone2 has bad quality
    stub_request(:get, 'https://build.kde.org/job/clone2/api/json')
      .to_return(body: JSON.generate(displayName: 'clone2'))
    stub_request(:get, 'https://build.kde.org/job/clone2/lastBuild/api/json')
      .to_return(body: JSON.generate(id: 16))
    stub_request(:get, 'https://build.kde.org/job/clone2/lastSuccessfulBuild/api/json')
      .to_return(body: JSON.generate(id: 15))
    stub_request(:get, 'https://build.kde.org/job/clone2/lastStableBuild/api/json')
      .to_return(body: JSON.generate(id: 15))
    stub_request(:get, 'https://build.kde.org/job/clone2/lastCompletedBuild/api/json')
      .to_return(body: JSON.generate(id: 16))

    data = {
      identifier: 'clone',
      vcs: ReleaseMe::Git.new,
      i18n_trunk: 'master',
      i18n_stable: 'master',
      i18n_path: ''
    }
    project = ReleaseMe::Project.new(data)
    project.vcs.repository = @remotedir

    # Release.rb will call abort once we tell it to not ignore the shitty jobs.
    # We intercept this and instead raise a sytemcallerror to verify that this
    # is in fact what occured.
    ReleaseMe::Release.any_instance.expects(:abort).raises(SystemCallError.new(''))
    ReleaseMe::Release.any_instance.expects(:gets).returns("n\n")
    assert_raises SystemCallError do
      ReleaseMe::Release.new(project, Origin::TRUNK, '1.0').get
    end
    assert_path_not_exist('clone-1.0')
  end
end
