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
    ReleaseMe::DocumentationL10n.new(ReleaseMe::DocumentationL10n::TRUNK, 'frenchfries', @i18n_path)
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
  end

  def test_get_doc
    # en & de
    d = create_doc
    d.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    d.get(@dir)
    assert_path_exist("#{@dir}/CMakeLists.txt")
    assert_path_exist("#{@dir}/doc/CMakeLists.txt")
    assert_path_exist("#{@dir}/doc/en/index.docbook")
    assert_path_exist("#{@dir}/doc/en/CMakeLists.txt")
    assert_path_exist("#{@dir}/doc/de/index.docbook")
    assert_path_exist("#{@dir}/doc/de/CMakeLists.txt")

    # en only (everything works if only doc/ is present in git but not
    # translated)
    d = create_doc_without_translation
    d.init_repo_url("file://#{Dir.pwd}/#{@svn_template_dir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    d.get(@dir)
    assert_path_exist("#{@dir}/CMakeLists.txt")
    assert_path_exist("#{@dir}/doc/CMakeLists.txt")
    assert_path_exist("#{@dir}/doc/en/index.docbook")
    assert_path_exist("#{@dir}/doc/en/CMakeLists.txt")
    refute_path_exist("#{@dir}/doc/de/index.docbook")
    refute_path_exist("#{@dir}/doc/de/CMakeLists.txt")
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
    # FIXME: I am actually not sure CMakeLists ought to be generated
    # recursively through 2->2.1->2.1.1 at all.
    expected_files = %w(
      CMakeLists.txt
      en
      en/CMakeLists.txt
      en/doc-valid2
      en/doc-valid2/CMakeLists.txt
      en/doc-valid2/index.docbook
      en/doc-valid2/doc-valid2.1
      en/doc-valid2/doc-valid2.1/CMakeLists.txt
      en/doc-valid2/doc-valid2.1/index.docbook
      en/doc-valid2/doc-valid2.1/doc-valid2.1.1
      en/doc-valid2/doc-valid2.1/doc-valid2.1.1/CMakeLists.txt
      en/doc-valid2/doc-valid2.1/doc-valid2.1.1/index.docbook
      en/doc-invalid1
      en/doc-valid1
      en/doc-valid1/CMakeLists.txt
      en/doc-valid1/index.docbook
      de
      de/CMakeLists.txt
      de/doc-valid2
      de/doc-valid2/CMakeLists.txt
      de/doc-valid2/index.docbook
      de/doc-valid2/doc-valid2.1
      de/doc-valid2/doc-valid2.1/CMakeLists.txt
      de/doc-valid2/doc-valid2.1/index.docbook
      de/doc-valid2/doc-valid2.1/doc-valid2.1.1
      de/doc-valid2/doc-valid2.1/doc-valid2.1.1/CMakeLists.txt
      de/doc-valid2/doc-valid2.1/doc-valid2.1.1/index.docbook
      de/doc-valid1
      de/doc-valid1/CMakeLists.txt
      de/doc-valid1/index.docbook
    )
    present_files = Dir.chdir("#{@dir}/doc/") { Dir.glob('**/**') }
    missing_files = []
    expected_files.each do |f|
      missing_files << f unless present_files.include?(f)
      present_files.delete(f)
    end
    assert(missing_files.empty?, "missing file(s): #{missing_files}")
    assert(present_files.empty?, "unexpected file(s): #{present_files}")

    # FIXME: check contents?
  end
end
