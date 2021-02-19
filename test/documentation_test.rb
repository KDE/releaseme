# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2014-2017 Harald Sitter <sitter@kde.org>

require 'fileutils'

require_relative 'lib/testme'
require_relative '../lib/releaseme/documentation.rb'
require_relative '../lib/releaseme/tmpdir'

# FIXME: test stable branch

class TestDocumentation < Testme
  # Initialize a persistent reference repo. This repo will get copied for each
  # test to start from a pristine state. svn is fairly expensive so creating
  # new repos when the content doesn't change is costing multiple seconds!
  # FIXME: code copy with l10n
  REFERENCE_TMPDIR, REFERENCE_REPO_PATH = begin
    tmpdir = ReleaseMe.mktmpdir(self.class.to_s) # cleaned via after_run hook
    repo_data_dir = data('l10nrepo/')

    svn_template_dir = "#{tmpdir}/tmp_l10n_repo"

    assert_run('svnadmin', 'create', svn_template_dir)
    raise unless File.exist?(svn_template_dir)

    ReleaseMe.mktmpdir(self.class.to_s) do |checkout_dir|
      checkout_dir = File.join(checkout_dir, "checkout")
      assert_run('svn', 'co', "file://#{svn_template_dir}", checkout_dir)
      FileUtils.cp_r("#{repo_data_dir}/trunk", checkout_dir)
      FileUtils.cp_r("#{repo_data_dir}/branches", checkout_dir)
      assert_run('svn', 'add', '--force', '.', chdir: checkout_dir)
      assert_run('svn', 'ci', '-m', 'yolo', chdir: checkout_dir)
    end

    [tmpdir, svn_template_dir]
  end

  Minitest.after_run do
    FileUtils.rm_rf(REFERENCE_TMPDIR)
  end

  def setup
    @i18n_path = 'amarok'
    @trunk_url = 'trunk/l10n-kf5/'
    @stable_url = 'branches/stable/l10n-kf5'

    @dir = 'tmp_l10n'
    @svn_template_dir = 'tmp_l10n_repo'
    FileUtils.cp_r(REFERENCE_REPO_PATH, @svn_template_dir)
    assert_path_exist(@svn_template_dir)

    ReleaseMe::DocumentationL10n.languages = nil
  end

  # TODO: attributes of documentation are not tested....
  def create_doc
    ReleaseMe::DocumentationL10n.new(ReleaseMe::DocumentationL10n::TRUNK,
                                     'amarok', @i18n_path)
  end

  def create_doc_without_translation
    ReleaseMe::DocumentationL10n.new(ReleaseMe::DocumentationL10n::TRUNK,
                                     'frenchfries', 'frenchfries')
  end

  def test_no_doc
    # no doc present
    d = ReleaseMe::DocumentationL10n.new(ReleaseMe::DocumentationL10n::TRUNK,
                                         'frenchfries',
                                         @i18n_path)
    d.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('variable-pot'), @dir)
    d.get(@dir)
    assert_path_exist("#{@dir}/Messages.sh")
    refute_path_exist("#{@dir}/doc")
    assert_equal([], Dir.glob("#{@dir}/po/*/docs"))
    refute_path_exist('CMakeLists.txt')
  end

  def test_get_doc
    # en & de
    d = create_doc
    d.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    d.get(@dir)
    Dir.chdir(@dir) do
      assert_includes(File.read('CMakeLists.txt'), 'kdoctools_install(po)')

      docs = Dir.glob('po/*/docs/*')
      assert_includes(docs, 'po/fr/docs/amarok')
      assert_includes(docs, 'po/de/docs/amarok')
      assert_equal(2, docs.size)

      # en tree is ok
      assert_path_exist('doc/index.docbook')
      # FIXME: should we require a cmakelists?
    end
  end

  def test_get_doc_without_l10n
    # en only (everything works if only doc/ is present in git but not
    # translated)
    d = create_doc_without_translation
    d.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    d.get(@dir)
    Dir.chdir(@dir) do
      refute_includes(File.read('CMakeLists.txt'), 'kdoctools_install(po)')

      assert_empty(Dir.glob('po/*/docs/*'))

      assert_path_exist('doc/CMakeLists.txt')
      assert_path_exist('doc/index.docbook')
    end
  end

  def test_get_doc_multi_doc
    d = ReleaseMe::DocumentationL10n.new(ReleaseMe::DocumentationL10n::TRUNK,
                                         'plasma-desktop',
                                         'kde-workspace')
    d.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('multi-doc'), @dir)
    d.get(@dir)
    # fr mustn't appear, it's empty
    expected_files = %w[
      CMakeLists.txt
      doc
      doc/CMakeLists.txt
      doc/doc-valid2
      doc/doc-valid2/CMakeLists.txt
      doc/doc-valid2/index.docbook
      doc/doc-valid2/doc-valid2.1
      doc/doc-valid2/doc-valid2.1/CMakeLists.txt
      doc/doc-valid2/doc-valid2.1/index.docbook
      doc/doc-valid2/doc-valid2.1/doc-valid2.1.1
      doc/doc-valid2/doc-valid2.1/doc-valid2.1.1/CMakeLists.txt
      doc/doc-valid2/doc-valid2.1/doc-valid2.1.1/index.docbook
      doc/doc-invalid1
      doc/doc-valid1
      doc/doc-valid1/CMakeLists.txt
      doc/doc-valid1/index.docbook
      po
      po/de
      po/de/docs
      po/de/docs/doc-valid2
      po/de/docs/doc-valid2/index.docbook
      po/de/docs/doc-valid2/doc-valid2.1
      po/de/docs/doc-valid2/doc-valid2.1/index.docbook
      po/de/docs/doc-valid2/doc-valid2.1/doc-valid2.1.1
      po/de/docs/doc-valid2/doc-valid2.1/doc-valid2.1.1/index.docbook
      po/de/docs/doc-valid1
      po/de/docs/doc-valid1/index.docbook
    ]
    present_files = Dir.chdir(@dir) { Dir.glob('**/**') }
    missing_files = []
    expected_files.each do |f|
      missing_files << f unless present_files.include?(f)
      present_files.delete(f)
    end
    assert(missing_files.empty?, "missing file(s): #{missing_files}")
    assert(present_files.empty?, "unexpected file(s): #{present_files}")

    Dir.chdir(@dir) do
      assert_includes(File.read('CMakeLists.txt'), 'kdoctools_install(po)')
    end
  end

  def test_man
    d = create_doc
    d.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('source-with-manpage'), @dir)
    d.get(@dir)
    Dir.chdir(@dir) do
      assert_includes(File.read('CMakeLists.txt'), 'kdoctools_install(po)')

      # NOTE: Our manpage line up is different from applications releases.
      #   We pack them into their original subdir whereas the other script
      #   packs them into the main dir. The reason is that we use the same code
      #   paths as for documentation which makes it cheaper for us to preserver
      #   the dir.
      docs = Dir.glob('po/*/docs/**/*.docbook')
      assert_includes(docs, 'po/de/docs/amarok/man-amarok.1.docbook')
      assert_includes(docs, 'po/de/docs/amarok/unicorn/man-unicorn.1.docbook')
      assert_equal(2, docs.size)
    end
  end

  def test_doc_excess_spacing
    # CMakeLists contains lots of excess spacing, regex should handle this and
    # be able to retrieve the l10n.
    d = create_doc
    d.init_repo_url("file:///#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('excess-spacing-doc'), @dir)
    d.get(@dir)
    Dir.chdir(@dir) do
      docs = Dir.glob('po/*/docs/*')
      assert_includes(docs, 'po/fr/docs/amarok')
      assert_includes(docs, 'po/de/docs/amarok')
      assert_equal(2, docs.size)
    end
  end
end
