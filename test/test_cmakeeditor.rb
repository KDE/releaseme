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

require_relative "lib/testme"

require_relative "../lib/cmakeeditor"

class TestCMakeEditor < Testme
  attr_accessor :dir
  attr_accessor :file
  attr_accessor :lang

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

  def assert_valid_kdoctools(file)
    p file
    parts = file.split('/')
    language = parts.first
    dir = parts[-2]
    expected_line = CMakeEditor.create_handbook(language, dir)
    assert_equal(expected_line, File.read(file))
  end

  def assert_equal_valid_meta_cmakelists(dir, file = 'CMakeLists.txt')
    Dir.chdir(dir) do
      dirs = Dir.glob('*').select { |f| File.directory?(f) }
      # FIXME: this again a variation of assert unordered nonesense lists
      # see below
      expected_subdirs = []
      dirs.each do |d|
        expected_subdirs << CMakeEditor.add_subdirectory(d).strip
      end
      present_subdirs = File.read(file).split($RS)
      missing_subdirs = []
      expected_subdirs.each do |f|
        missing_subdirs << f unless present_subdirs.include?(f)
        present_subdirs.delete(f)
      end
      assert(missing_subdirs.empty?, "missing dir(S): #{missing_subdirs}")
      assert(present_subdirs.empty?, "unexpected dir(s): #{present_subdirs}")
    end
  end

  def test_create_handbook_complex
    # tmpdir now conflicts with testme...
    FileUtils.rm_rf(@dir)
    origin_dir = "#{@datadir}/cmakeeditor/#{__method__}"
    FileUtils.cp_r(Dir.glob("#{origin_dir}/*"), '.', verbose: true)
    %w(en_US de fr).each do |lang|
      CMakeEditor.create_language_specific_doc_lists!("#{Dir.pwd}/#{lang}", lang, 'yolo')
    end
    # FIXME: put in testme as assert_files_exist
    expected_files = %w(
      CMakeLists.txt
      fr
      fr/CMakeLists.txt
      fr/doc2
      fr/doc2/CMakeLists.txt
      fr/doc2/index.docbook
      en_US
      en_US/CMakeLists.txt
      en_US/doc1
      en_US/doc1/CMakeLists.txt
      en_US/doc1/index.docbook
      en_US/doc2
      en_US/doc2/CMakeLists.txt
      en_US/doc2/index.docbook
      de
      de/CMakeLists.txt
      de/doc1
      de/doc1/CMakeLists.txt
      de/doc1/index.docbook
    )
    present_files = Dir.glob('**/**')
    missing_files = []
    expected_files.each do |f|
      missing_files << f unless present_files.include?(f)
      present_files.delete(f)
    end
    assert(missing_files.empty?, "missing file(S): #{missing_files}")
    assert(present_files.empty?, "unexpected file(s): #{present_files}")
    assert_equal_valid_meta_cmakelists('.')
    assert_equal(File.read('en_US/CMakeLists.txt'),
                 File.read('fr/CMakeLists.txt'))
    assert_valid_kdoctools('fr/doc2/CMakeLists.txt')
    assert_valid_kdoctools('en_US/doc1/CMakeLists.txt')
    assert_valid_kdoctools('en_US/doc2/CMakeLists.txt')
    assert_equal(File.read('en_US/CMakeLists.txt'),
                 File.read('de/CMakeLists.txt'))
    assert_valid_kdoctools('de/doc1/CMakeLists.txt')
  end

  def test_create_language_specific_handbook_lists
    # Internally create attempts to find the most meaningful creation which
    # involves checking whether the doc dir even is valid and possibly
    # refusing to write anything when not, so make the doc dir the least bit
    # valid by creating index.docbook.
    FileUtils.touch("#{dir}/index.docbook")
    CMakeEditor.create_language_specific_doc_lists!(dir, lang, 'yolo')
    assert(File.exist?(file))
    data = File.read(file)
    assert_equal(CMakeEditor.create_handbook(lang, 'yolo'), data)
    assert_has_terminal_newline(data)
  end

  def test_create_handbook_uses_basename
    lang = 'fr'
    with_path = CMakeEditor.create_handbook(lang, '/tmp/kittens')
    with_name = CMakeEditor.create_handbook(lang, 'kittens')
    assert_equal(with_path, with_name)
  end

  def test_create_doc_meta_lists
    Dir.mkdir("#{dir}/aa")
    Dir.mkdir("#{dir}/bb")
    Dir.mkdir("#{dir}/cc")
    CMakeEditor.create_doc_meta_lists!(dir)
    assert(File.exist?(file))
    data = File.read(file)
    assert(!data.downcase.include?("find_package(gettext")) # PO-only!
    assert(data.downcase.include?("add_subdirectory(aa)"))
    assert(data.downcase.include?("add_subdirectory(bb)"))
    assert(data.downcase.include?("add_subdirectory(cc)"))
    assert_has_terminal_newline(data)
  end

  def create_cmakelists!
    f = File.new(@file, File::CREAT | File::RDWR | File::TRUNC)
    f << "#FOO_SUBDIR\n"
    f.close
  end

  def test_append_po_install_instructions_append
    create_cmakelists!
    CMakeEditor::append_po_install_instructions!(dir, 'po')
    assert(File::exists?(file))
    data = File.read(file)
    assert(data.include?("#FOO_SUBDIR\n"))
    assert(data.include?("ki18n_install(po)"))
    assert_has_terminal_newline(data)
    # Make sure the editor doesn't append if it is already there...
    CMakeEditor::append_po_install_instructions!(dir, 'po')
    data = File.read(file)
    assert(data.scan('ki18n_install(po)').count == 1)
  end

  def test_append_po_install_instructions_substitute
    create_cmakelists!
    CMakeEditor::append_po_install_instructions!(dir, 'foo')
    assert(File::exists?(file))
    data = File.read(file)
    assert(!data.include?("#FOO_SUBDIR\n"))
    assert(data.include?("ki18n_install(foo)"))
    assert_has_terminal_newline(data)
  end

  def test_append_optional_add_subdirectory_append
    create_cmakelists!
    CMakeEditor::append_optional_add_subdirectory!(dir, 'append')
    assert(File::exists?(file))
    data = File.read(file)
    assert(data.include?("#FOO_SUBDIR\n"))
    assert(data.include?("add_subdirectory(append)"))
    assert_has_terminal_newline(data)
    # Make sure the editor doesn't append if it is already there...
    CMakeEditor::append_optional_add_subdirectory!(dir, 'po')
    data = File.read(file)
    assert(data.scan('add_subdirectory(append)').count == 1)
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
