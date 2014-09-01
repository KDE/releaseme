require "fileutils"
require "test/unit"

require_relative "../kdel10n.rb"
require_relative "../l10nstatistics.rb"
require_relative "../documentation.rb"

class TestL10n < Test::Unit::TestCase
    def setup
        puts "TODO NEED TO TEST STABLE>>>>>>>>>"
        @dataDir = "data/"
        @repoDataDir = "#{@dataDir}/l10nrepo/"

        @module = "extragear"
        @section = "multimedia"

        @trunkUrl = "trunk/l10n-kf5/"
        @stableUrl = "branches/stable/l10n-kf5"

        @dir = "tmp_l10n_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        @svnTemplateDir = "tmp_l10n_repo_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        @svnCheckoutDir = "tmp_l10n_check_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join

        %x{svnadmin create #{@svnTemplateDir}}
        assert(File::exists?(@svnTemplateDir))

        %x{svn co file://#{Dir.pwd}/#{@svnTemplateDir} #{@svnCheckoutDir}}
        FileUtils.cp_r("#{@repoDataDir}/trunk", @svnCheckoutDir)
        FileUtils.cp_r("#{@repoDataDir}/branches", @svnCheckoutDir)
        Dir.chdir(@svnCheckoutDir)
        %x{svn add *}
        %x{svn ci -m 'yolo'}
        Dir.chdir("..")
    end

    def teardown
        FileUtils.rm_rf(@svnTemplateDir)
        FileUtils.rm_rf(@svnCheckoutDir)
        FileUtils.rm_rf(@dir)
    end

    def create_l10n
        l = KdeL10n.new(KdeL10n::TRUNK, @module, @section)
        l.target = "#{@dir}/l10n"
        return l
    end

    def test_0_attr
        l = create_l10n()

        assert_equal(l.target, "#{@dir}/l10n")
        assert_equal(l.type, KdeL10n::TRUNK)
        assert_equal(l.module, "extragear")
        assert_equal(l.section, "multimedia")
    end

    def test_0_repo_url_init
        l = create_l10n()
        assert_equal(l.type, KdeL10n::TRUNK)
        l.initRepoUrl("file://a")
        assert_equal(l.vcs.repository, "file://a/trunk//l10n-kf5/")
        l.initRepoUrl("file://a/")
        assert_equal(l.vcs.repository, "file://a/trunk//l10n-kf5/")
    end

    def test_find_templates
        l = create_l10n()

        templates = l.find_templates("data/multi-pot")
        assert_equal(templates.count, 2)

        templates = l.find_templates("data/single-pot")
        assert_equal(templates.count, 1)
    end

    def test_get_po
        l = create_l10n()
        l.initRepoUrl("file://#{Dir.pwd}/#{@svnTemplateDir}")

        FileUtils.rm_rf(@dir)
        FileUtils.cp_r("data/single-pot", @dir)
        l.get(@dir)
        assert(File::exists?("#{@dir}"))
        assert(File::exists?("#{@dir}/CMakeLists.txt"))
        assert(!File::exists?("#{@dir}/l10n")) # temp dir must not be there
        assert(File::exists?("#{@dir}/po"))
        assert(File::exists?("#{@dir}/po/de/amarok.po"))

        FileUtils.rm_rf(@dir)
        FileUtils.cp_r("data/multi-pot", @dir)
        l.get(@dir)
        assert(File::exists?("#{@dir}"))
        assert(File::exists?("#{@dir}/CMakeLists.txt"))
        assert(!File::exists?("#{@dir}/l10n")) # temp dir must not be there
        assert(File::exists?("#{@dir}/po"))
        assert(File::exists?("#{@dir}/po/de/amarok.po"))
        assert(File::exists?("#{@dir}/po/de/amarokcollectionscanner_qt.po"))
    end

    def test_statistics
        l = create_l10n()
        l.initRepoUrl("file://#{Dir.pwd}/#{@svnTemplateDir}")

        FileUtils.rm_rf(@dir)
        FileUtils.cp_r("data/multi-pot", @dir)
        l.get(@dir)

        statistics = L10nStatistics.new
        statistics.gather!(@dir)
        assert(statistics.stats == {"de"=>{:all=>4,
                                           :shown=>3,
                                           :notshown=>1,
                                           :percentage=>75.0},
                                    "fr"=>{:all=>4,
                                           :shown=>4,
                                           :notshown=>0,
                                           :percentage=>100.0}})
    end

    def create_doc
        l = DocumentationL10n.new(DocumentationL10n::TRUNK, "amarok", @module, @section)
        return l
    end

    def create_doc_without_translation
        l = DocumentationL10n.new(DocumentationL10n::TRUNK, "frenchfries", @module, @section)
        return l
    end

    def test_get_doc
        # en_US & de
        d = create_doc()
        d.initRepoUrl("file://#{Dir.pwd}/#{@svnTemplateDir}")
        FileUtils.rm_rf(@dir)
        FileUtils.cp_r("data/single-pot", @dir)
        d.get(@dir)
        assert(File::exists?("#{@dir}/CMakeLists.txt"))
        assert(File::exists?("#{@dir}/doc/CMakeLists.txt"))
        assert(File::exists?("#{@dir}/doc/en_US/index.docbook"))
        assert(File::exists?("#{@dir}/doc/en_US/CMakeLists.txt"))
        assert(File::exists?("#{@dir}/doc/de/index.docbook"))
        assert(File::exists?("#{@dir}/doc/de/CMakeLists.txt"))

        # en_US only (everything works if only doc/ is present in git but not translated)
        d = create_doc_without_translation()
        d.initRepoUrl("file://#{Dir.pwd}/#{@svnTemplateDir}")
        FileUtils.rm_rf(@dir)
        FileUtils.cp_r("data/single-pot", @dir)
        d.get(@dir)
        assert(File::exists?("#{@dir}/CMakeLists.txt"))
        assert(File::exists?("#{@dir}/doc/CMakeLists.txt"))
        assert(File::exists?("#{@dir}/doc/en_US/index.docbook"))
        assert(File::exists?("#{@dir}/doc/en_US/CMakeLists.txt"))
        assert(!File::exists?("#{@dir}/doc/de/index.docbook"))
        assert(!File::exists?("#{@dir}/doc/de/CMakeLists.txt"))
    end
end
