require 'fileutils'

require_relative 'lib/testme'

require_relative '../lib/documentation.rb'

# FIXME: test stable branch

class TestDocumentation < Testme
  def setup
    # FIXME: code copy with l10n
    @repoDataDir = data('l10nrepo/')

    @i18n_path = 'extragear-multimedia'

    @trunkUrl = 'trunk/l10n-kf5/'
    @stableUrl = 'branches/stable/l10n-kf5'

    @dir = "tmp_l10n_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
    @svnTemplateDir = "tmp_l10n_repo_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
    @svnCheckoutDir = "tmp_l10n_check_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join

    `svnadmin create #{@svnTemplateDir}`
    assert(File.exist?(@svnTemplateDir))

    `svn co file://#{Dir.pwd}/#{@svnTemplateDir} #{@svnCheckoutDir}`
    FileUtils.cp_r("#{@repoDataDir}/trunk", @svnCheckoutDir)
    FileUtils.cp_r("#{@repoDataDir}/branches", @svnCheckoutDir)
    Dir.chdir(@svnCheckoutDir) do
      `svn add *`
      `svn ci -m 'yolo'`
    end
  end

  def teardown
    FileUtils.rm_rf(@svnTemplateDir)
    FileUtils.rm_rf(@svnCheckoutDir)
    FileUtils.rm_rf(@dir)
  end

  # TODO: attributes of documentation are not tested....
  def create_doc
    DocumentationL10n.new(DocumentationL10n::TRUNK, 'amarok', @i18n_path)
  end

  def create_doc_without_translation
    DocumentationL10n.new(DocumentationL10n::TRUNK, 'frenchfries', @i18n_path)
  end

  def test_get_doc
    # en & de
    d = create_doc
    d.init_repo_url("file://#{Dir.pwd}/#{@svnTemplateDir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    d.get(@dir)
    assert(File.exist?("#{@dir}/CMakeLists.txt"))
    assert(File.exist?("#{@dir}/doc/CMakeLists.txt"))
    assert(File.exist?("#{@dir}/doc/en/index.docbook"))
    assert(File.exist?("#{@dir}/doc/en/CMakeLists.txt"))
    assert(File.exist?("#{@dir}/doc/de/index.docbook"))
    assert(File.exist?("#{@dir}/doc/de/CMakeLists.txt"))

    # en only (everything works if only doc/ is present in git but not
    # translated)
    d = create_doc_without_translation
    d.init_repo_url("file://#{Dir.pwd}/#{@svnTemplateDir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('single-pot'), @dir)
    d.get(@dir)
    assert(File.exist?("#{@dir}/CMakeLists.txt"))
    assert(File.exist?("#{@dir}/doc/CMakeLists.txt"))
    assert(File.exist?("#{@dir}/doc/en/index.docbook"))
    assert(File.exist?("#{@dir}/doc/en/CMakeLists.txt"))
    assert(!File.exist?("#{@dir}/doc/de/index.docbook"))
    assert(!File.exist?("#{@dir}/doc/de/CMakeLists.txt"))
  end

  def test_get_doc_multi_doc
    d = DocumentationL10n.new(DocumentationL10n::TRUNK,
                              'plasma-desktop',
                              'kde-workspace')
    d.init_repo_url("file://#{Dir.pwd}/#{@svnTemplateDir}")
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

  def test_divergent_lineup garbage
    d = DocumentationL10n.new(DocumentationL10n::TRUNK, 'powerdevil', 'kde-workspace')
    d.init_repo_url("file://#{Dir.pwd}/#{@svnTemplateDir}")
    FileUtils.rm_rf(@dir)
    FileUtils.cp_r(data('test_divergent_lineup'), @dir)
    d.get(@dir)
    expected_files = %w(
      CMakeLists.txt
      en
      en/CMakeLists.txt
      en/kcm
      en/kcm/CMakeLists.txt
      en/kcm/index.docbook
      de/CMakeLists.txt
      de/kcontrol
      de/kcontrol/CMakeLists.txt
      de/kcontrol/powerdevil
      de/kcontrol/powerdevil/CMakeLists.txt
      de/kcontrol/powerdevil/index.docbook
    )
    present_files = Dir.chdir("#{@dir}/doc/") { Dir.glob('**/**') }
    missing_files = []
    expected_files.each do |f|
      missing_files << f unless present_files.include?(f)
      present_files.delete(f)
    end
    assert(missing_files.empty?, "missing file(S): #{missing_files}")
    assert(present_files.empty?, "unexpected file(s): #{present_files}")
  end
end
