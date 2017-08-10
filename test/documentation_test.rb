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

require 'fileutils'

require_relative 'lib/testme'
require_relative '../lib/releaseme/documentation.rb'

# FIXME: test stable branch

class TestDocumentation < Testme
  def setup
    # FIXME: code copy with l10n
    @repo_data_dir = data('l10nrepo/')

    @i18n_path = 'extragear-multimedia'

    @trunk_url = 'trunk/l10n-kf5/'
    @stable_url = 'branches/stable/l10n-kf5'

    @dir = 'tmp_l10n_' + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
    @svn_template_dir = 'tmp_l10n_repo_' + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
    @svn_checkout_dir = 'tmp_l10n_check_' + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join

    system("svnadmin create #{@svn_template_dir}", [:out] => '/dev/null')
    assert_path_exist(@svn_template_dir)

    system("svn co file://#{Dir.pwd}/#{@svn_template_dir} #{@svn_checkout_dir}",
           [:out] => '/dev/null')
    FileUtils.cp_r("#{@repo_data_dir}/trunk", @svn_checkout_dir)
    FileUtils.cp_r("#{@repo_data_dir}/branches", @svn_checkout_dir)
    system('svn add *', chdir: @svn_checkout_dir, [:out] => '/dev/null')
    system("svn ci -m 'yolo'", chdir: @svn_checkout_dir, [:out] => '/dev/null')

    ReleaseMe::DocumentationL10n.languages = nil
  end

  def teardown
    FileUtils.rm_rf(@svn_template_dir)
    FileUtils.rm_rf(@svn_checkout_dir)
    FileUtils.rm_rf(@dir)
  end

  # TODO: attributes of documentation are not tested....
  def create_doc
    ReleaseMe::DocumentationL10n.new(ReleaseMe::DocumentationL10n::TRUNK, 'amarok', @i18n_path)
  end

  def create_doc_without_translation
    ReleaseMe::DocumentationL10n.new(ReleaseMe::DocumentationL10n::TRUNK, 'frenchfries', 'frenchfries')
  end

  def test_no_doc
    # no doc present
    d = ReleaseMe::DocumentationL10n.new(ReleaseMe::DocumentationL10n::TRUNK,
                              'frenchfries',
                              @i18n_path)
    d.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")
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
    d.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")
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
    d.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")
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
    d.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")
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
    d.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")
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
end
