# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2014-2017 Harald Sitter <sitter@kde.org>

require 'fileutils'

require_relative 'lib/testme'
require_relative '../lib/releaseme/cmakeeditor'

class TestCMakeEditor < Testme
  def assert_has_terminal_newline(data)
    assert(data.end_with?("\n"))
  end

  def assert_equal_valid_meta_cmakelists(dir, file = 'CMakeLists.txt')
    Dir.chdir(dir) do
      dirs = Dir.glob('*').select { |f| File.directory?(f) }
      # FIXME: this again a variation of assert unordered nonesense lists
      # see below
      expected_subdirs = []
      dirs.each do |d|
        expected_subdirs << ReleaseMe::CMakeEditor.add_subdirectory(d).strip
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

  def create_cmakelists!
    f = File.new('CMakeLists.txt', File::CREAT | File::RDWR | File::TRUNC)
    f << "#FOO_SUBDIR\n"
    f.close
  end

  def test_append_po_install_instructions
    create_cmakelists!
    ReleaseMe::CMakeEditor.append_po_install_instructions!(Dir.pwd, 'po')
    # FIXME: lots of code dup like this
    assert_path_exist('CMakeLists.txt')
    data = File.read('CMakeLists.txt')
    assert(data.include?("#FOO_SUBDIR\n"))
    assert(data.include?('ki18n_install(po)'))
    assert_has_terminal_newline(data)
    # Make sure the editor doesn't append if it is already there...
    ReleaseMe::CMakeEditor.append_po_install_instructions!(Dir.pwd, 'po')
    data = File.read('CMakeLists.txt')
    assert_includes(data, 'ki18n_install(po)')
  end

  def test_append_po_install_instructions_with_ecm_to_qm
    File.write('CMakeLists.txt', '   ecm_install_po_files_as_qm (    po    )  ')
    ReleaseMe::CMakeEditor.append_po_install_instructions!(Dir.pwd, 'po')
    data = File.read('CMakeLists.txt')
    refute_includes(data, 'ki18n_install(po)')
  end

  def test_append_po_install_instructions_substitute
    create_cmakelists!
    ReleaseMe::CMakeEditor.append_po_install_instructions!(Dir.pwd, 'foo')
    assert_path_exist('CMakeLists.txt')
    data = File.read('CMakeLists.txt')
    assert(!data.include?("#FOO_SUBDIR\n"))
    assert(data.include?('ki18n_install(foo)'))
    assert_has_terminal_newline(data)
  end

  def test_append_optional_add_subdirectory_append
    create_cmakelists!
    ReleaseMe::CMakeEditor.append_optional_add_subdirectory!(Dir.pwd, 'append')
    assert_path_exist('CMakeLists.txt')
    data = File.read('CMakeLists.txt')
    assert(data.include?("#FOO_SUBDIR\n"))
    assert(data.include?('add_subdirectory(append)'))
    assert_has_terminal_newline(data)
    # Make sure the editor doesn't append if it is already there...
    ReleaseMe::CMakeEditor.append_optional_add_subdirectory!(Dir.pwd, 'po')
    data = File.read('CMakeLists.txt')
    assert_includes(data, 'add_subdirectory(append)')
  end

  def test_append_optional_add_subdirectory_substitute
    create_cmakelists!
    ReleaseMe::CMakeEditor.append_optional_add_subdirectory!(Dir.pwd, 'foo')
    assert_path_exist('CMakeLists.txt')
    data = File.read('CMakeLists.txt')
    assert(!data.include?("#FOO_SUBDIR\n"))
    assert(data.include?('ECMOptionalAddSubdirectory'))
    assert(data.include?('ecm_optional_add_subdirectory(foo'))
    assert_has_terminal_newline(data)
  end

  def skip_options(d)
    d = d.upcase
    [
      "# SKIP_#{d}_INSTALL",
      "# SKIP_#{d}_INSTALL fishy sail",
      "    # SKIP_#{d}_INSTALL",
      "    # SKIP_#{d}_INSTALL    ",
      "#SKIP_#{d}_INSTALL    ",
      " beeep #SKIP_#{d}_INSTALL"
    ]
  end

  def test_skipperino
    # SKIP_FOO_INSTALL can be used as a comment anywhere in a to-be-mangled
    # CMakeLists.txt to prevent the mangling from a source level. This overrides
    # whatever releaseme wants to do or is instructed to do!

    skip_options('po').each do |comment|
      File.write('CMakeLists.txt', comment)
      ReleaseMe::CMakeEditor.append_po_install_instructions!("#{Dir.pwd}/po")
      assert_equal(comment, File.read('CMakeLists.txt'), 'po')
    end

    skip_options('poqm').each do |comment|
      File.write('CMakeLists.txt', comment)
      ReleaseMe::CMakeEditor.append_poqm_install_instructions!("#{Dir.pwd}/poqm")
      assert_equal(comment, File.read('CMakeLists.txt'), 'poqm')
    end

    skip_options('doc').each do |comment|
      File.write('CMakeLists.txt', comment)
      ReleaseMe::CMakeEditor.append_optional_add_subdirectory!("#{Dir.pwd}/doc")
      assert_equal(comment, File.read('CMakeLists.txt'), 'doc')
    end
  end
end
