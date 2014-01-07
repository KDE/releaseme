#--
# Copyright (C) 2014 Harald Sitter <apachelogger@ubuntu.com>
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

require "fileutils"
require "test/unit"

require_relative "../cmakeeditor"

class TestCMakeEditor < Test::Unit::TestCase
    attr :dir
    attr :file
    attr :lang

    def setup
        @dir = Dir.pwd + "/tmp_cmakeeditor_" + (0...16).map{ ('a'..'z').to_a[rand(26)] }.join
        Dir.mkdir(@dir)
        @file = @dir + "/CMakeLists.txt"
        @lang = 'xx'
    end

    def teardown
        FileUtils.rm_rf(@dir)
    end

    def assert_has_terminal_newline(data)
        assert(data.end_with?("\n"))
    end

    def test_create_language_specific_lists
        CMakeEditor::create_language_specific_lists!(dir, lang)
        assert(File::exists?(file))
        data = File.read(file)
        assert(data.downcase.include?("gettext_process_po_files(#{lang}"))
        assert_has_terminal_newline(data)
    end

    def test_create_po_meta_lists
        Dir.mkdir("#{dir}/aa")
        Dir.mkdir("#{dir}/bb")
        Dir.mkdir("#{dir}/cc")
        CMakeEditor::create_po_meta_lists!(dir)
        assert(File::exists?(file))
        data = File.read(file)
        assert(data.downcase.include?("find_package(gettext"))
        assert(data.downcase.include?("add_subdirectory(aa)"))
        assert(data.downcase.include?("add_subdirectory(bb)"))
        assert(data.downcase.include?("add_subdirectory(cc)"))
        assert_has_terminal_newline(data)
    end

    def create_cmakelists!
        f = File.new(@file, File::CREAT | File::RDWR | File::TRUNC)
        f << "#PO_SUBDIR\n"
        f.close
    end

    def test_append_optional_add_subdirectory_append
        create_cmakelists!
        CMakeEditor::append_optional_add_subdirectory!(dir, 'append')
        assert(File::exists?(file))
        data = File.read(file)
        assert(data.include?("#PO_SUBDIR\n"))
        assert(data.include?("MacroOptionalAddSubdirectory"))
        assert(data.include?("add_subdirectory(append"))
        assert_has_terminal_newline(data)
    end

    def test_append_optional_add_subdirectory_substitute
        return
        create_cmakelists!
        CMakeEditor::append_optional_add_subdirectory!(dir, 'po')
        assert(File::exists?(file))
        data = File.read(file)
        assert(!data.include?("#PO_SUBDIR\n"))
        assert(data.include?("MacroOptionalAddSubdirectory"))
        assert(data.include?("add_subdirectory(po"))
        assert_has_terminal_newline(data)
    end
end
