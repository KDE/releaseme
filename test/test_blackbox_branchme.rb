require "fileutils"
require "tmpdir"

require_relative "lib/testme"

class TestBlackboxBranchme < Testme
    def cleanup_libdebconf(branchname)
        FileUtils.rm_rf("gitclone")
        system("git clone kde:libdebconf-kde.git gitclone")
        Dir.chdir("gitclone") do
            system("git push origin :#{branchname}")
        end
        FileUtils.rm_rf("gitclone")
    end

    def test_git
        branchname = "sitter/branchme-test"
        cleanup_libdebconf(branchname)

        FileUtils.cp("#{@datadir}/blackbox/release_data", ".")
        assert_path_exist("release_data")

        # FIXME: make bindir?

        ret = system("ruby #{@testdir}/../branchme.rb --name #{branchname}")
        assert(ret)

        assert system("git clone kde:libdebconf-kde.git gitclone")
        Dir.chdir("gitclone") do
            system("git branch -a")
            # FIXME: need a release_data parser or something and compare hash as well
            assert system("git show-branch origin/#{branchname}"), "branch not found"
            assert system("git checkout #{branchname}"), "branch checkout failed"
            assert system("git push origin :#{branchname}"), "couldn't delete branch"
            assert !system("git show-branch origin/#{branchname}"), "branch is not gone after delete"
        end

    ensure
        cleanup_libdebconf(branchname)
    end
end
