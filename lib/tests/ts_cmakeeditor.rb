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

    def test_create_language_specific_handbook_lists
        # Internally create attempts to find the most meaningful creation which
        # involves checking whether the doc dir even is valid and possibly
        # refusing to write anything when not, so make the doc dir the least bit
        # valid by creating index.docbook.
        FileUtils.touch('index.docbook')
        CMakeEditor::create_language_specific_doc_lists!(dir, lang, "yolo")
        assert(File::exists?(file))
        data = File.read(file)
        assert(data.downcase.include?('kdoctools_create_handbook(index.docbook install_destination ${html_install_dir}/xx subdir yolo)'))
        assert_has_terminal_newline(data)
    end

    def test_create_doc_meta_lists
        Dir.mkdir("#{dir}/aa")
        Dir.mkdir("#{dir}/bb")
        Dir.mkdir("#{dir}/cc")
        CMakeEditor::create_doc_meta_lists!(dir)
        assert(File::exists?(file))
        data = File.read(file)
        assert(!data.downcase.include?("find_package(gettext")) # PO-only!
        assert(data.downcase.include?("add_subdirectory(aa)"))
        assert(data.downcase.include?("add_subdirectory(bb)"))
        assert(data.downcase.include?("add_subdirectory(cc)"))
        assert_has_terminal_newline(data)
    end

    def test_append_po_install_instructions
        create_cmakelists!
        CMakeEditor::append_po_install_instructions!(dir, 'po')
        assert(File::exists?(file))
        data = File.read(file)
        assert(data.downcase.include?("ki18n_install(po)"))
        assert_has_terminal_newline(data)
    end

    def create_cmakelists!
        f = File.new(@file, File::CREAT | File::RDWR | File::TRUNC)
        f << "#FOO_SUBDIR\n"
        f.close
    end

    def test_append_optional_add_subdirectory_append
        create_cmakelists!
        CMakeEditor::append_optional_add_subdirectory!(dir, 'append')
        assert(File::exists?(file))
        data = File.read(file)
        assert(data.include?("#FOO_SUBDIR\n"))
        assert(data.include?("add_subdirectory(append"))
        assert_has_terminal_newline(data)
    end

    def test_append_optional_add_subdirectory_substitute
        create_cmakelists!
        CMakeEditor::append_optional_add_subdirectory!(dir, 'foo')
        assert(File::exists?(file))
        data = File.read(file)
        assert(!data.include?("#FOO_SUBDIR\n"))
        assert(data.include?("ECMOptionalAddSubdirectory"))
        assert(data.include?("ecm_optional_add_subdirectory(foo"))
        assert_has_terminal_newline(data)
    end
end
