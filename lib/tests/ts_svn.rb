require "fileutils"
require "test/unit"

require_relative "../kdegitrelease.rb"

class TestSvn < Test::Unit::TestCase
    def setup
        @svnCheckoutDir = Dir.pwd + "/tmp_check_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        @svnRepoDir = Dir.pwd + "/tmp_repo_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        %x[svnadmin create #{@svnRepoDir}]
        assert(File::exists?(@svnRepoDir))
    end

    def teardown
        FileUtils.rm_rf(@svnRepoDir)
        FileUtils.rm_rf(@svnCheckoutDir)
    end

    def test_get
        s = Svn.new()

        s.repository = "file://#{@svnRepoDir}"
        s.get(@svnCheckoutDir)
        assert(File::exists?(@svnCheckoutDir))
        FileUtils.rm_rf(@svnCheckoutDir)

        s.repository = "file://foofooofoo"
        s.get(@svnCheckoutDir)
        assert(!File::exists?(@svnCheckoutDir))
        FileUtils.rm_rf(@svnCheckoutDir)
    end
end
