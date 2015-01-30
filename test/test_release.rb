require_relative 'lib/testme'

require_relative '../lib/git'
require_relative '../lib/project'
require_relative '../lib/release'

module Silencer
  module_function

  def run(cmd)
    `#{cmd} 2>&1`
  end
end

class TestRelease < Testme
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

    # Teardown happens automatically when the @tmpdir is torn down
  end

  def test_get_archive_cleanup
    data = {
      :identifier => 'clone',
      :vcs => Git.new,
      :i18n_trunk => 'master',
      :i18n_stable => 'master',
      :i18n_path => ''
    }
    project = Project.new(data)
    project.vcs.repository = @remotedir

    @dir = "#{Dir.pwd}/clone"
    r = Release.new(project)
    r.source.target = @dir

    assert(!File.exist?(@dir))
    r.get
    assert(File.exist?(@dir))
    assert(File.exist?("#{@dir}/file"))

    assert(!File.exist?("#{@dir}.tar.xz"))
    r.archive
    assert(File.exist?("#{@dir}.tar.xz"))

    assert(File.exist?(@dir))
    r.source.cleanup
    assert(!File.exist?(@dir))
  end
end
