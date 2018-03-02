#--
# Copyright (C) 2007-2017 Harald Sitter <sitter@kde.org>
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
require 'pathname'

require_relative 'logable'

module ReleaseMe
  # General purpose CMakeLists.txt editing functions
  module CMakeEditor
    include Logable

    module_function

    def add_subdirectory(path, relative_to: nil)
      rel = path.dup
      if relative_to
        rel = Pathname.new(rel).relative_path_from(Pathname.new(relative_to))
      end
      "add_subdirectory(#{rel})\n"
    end

    # Base class for cmake editor implementations.
    # An editor opens a cmakelists and edits it to fit a certain expectation.
    # An editor always works with a cmakelists inside a dir and adds/changes
    # the reference to a given subdir (e.g. doc/).
    # Editing does not happen if `# SKIP_$SUBDIR_INSTALL` is in the CMakeLists.
    # If ``#$SUBDIR_SUBDIR` is in the CMakeLists the comment will be replaced
    # with the actual code (handy for if conditionally the entire block).
    # Otherwise the block will be appended to the file.
    #
    # An editor needs to implement a method `macro` which returns a string
    # of the block to paste into the file.
    # It also needs `already_edited?` to regex the content to determine
    # if the functional bit of the maybe is already in the file (e.g.
    # ki18n_install is already called somewhere).
    class CMakeEditorBase
      # The directory in which we want to edit the cmakelists
      attr_reader :dir

      # The directory which we are referencing in the edit.
      attr_reader :subdir

      # Data of the cmakelists, only available during editing!
      attr_reader :data

      def initialize(dir, subdir: nil)
        @dir = dir
        @subdir = subdir
        @dir, @subdir = dir_subdir_split(dir) unless subdir
      end

      def run
        edit_file("#{dir}/CMakeLists.txt") do
          break if skip? || already_edited?
          edit!
        end
      end

      private

      def edit!
        if data.include?("##{subdir.upcase}_SUBDIR")
          data.sub!("##{subdir.upcase}_SUBDIR", macro)
        else
          # TODO: needs test case
          # Mighty fancy regex looking for existing add_subdir.
          # Basically allows spaces everywhere one might want to put spaces.
          # At the end we allow everything as there may be a comment for
          # example.
          data << macro
        end
      end

      # Checks if data contains a cmake method call with subdir as argument
      def subdir_method_call?(method_pattern)
        data =~ method_call_regex_of(method_pattern)
      end

      def method_call_regex_of(method_pattern)
        /^\s*(#{method_pattern})\s*\(\s*#{subdir}\s*\).*$/i
      end

      def skip?
        data =~ /.*#\s*SKIP_#{subdir.upcase}_INSTALL/
      end

      def edit_file(file)
        @data = File.read(file)
        yield
        File.write(file, @data)
      end

      def dir_subdir_split(dir)
        [File.dirname(dir), File.basename(dir)]
      end
    end

    # Appends the install instructions for po/*
    class AppendPOInstallInstructions < CMakeEditorBase
      def already_edited?
        subdir_method_call?('ki18n_install') ||
          subdir_method_call?('ecm_install_po_files_as_qm')
      end

      def macro
        "\n" + <<-CMAKE
find_package(KF5I18n CONFIG REQUIRED)
ki18n_install(#{subdir})
      CMAKE
      end
    end

    # Compatibility, see AppendPOInstallInstructions.
    def append_po_install_instructions!(dir, subdir = nil)
      AppendPOInstallInstructions.new(dir, subdir: subdir).run
    end

    # Appends the install instructions for poqm/*
    class AppendPOQMInstallInstructions < CMakeEditorBase
      def already_edited?
        subdir_method_call?('ecm_install_po_files_as_qm')
      end

      def macro
        "\necm_install_po_files_as_qm(#{subdir})\n"
      end
    end

    # Compatibility, see AppendPOQMInstallInstructions.
    def append_poqm_install_instructions!(dir, subdir = nil)
      AppendPOQMInstallInstructions.new(dir, subdir: subdir).run
    end

    # Appends the install instructions for documentation in po/*
    class AppendDocInstallInstructions < CMakeEditorBase
      def already_edited?
        subdir_method_call?('kdoctools_install')
      end

      def macro
        "\n" + <<-CMAKE
  find_package(KF5DocTools CONFIG)
  if(KF5DocTools_FOUND)
    kdoctools_install(#{subdir})
  endif()
        CMAKE
      end
    end

    # Compatibility, see AppendDocInstallInstructions.
    def append_doc_install_instructions!(dir, subdir = nil)
      AppendDocInstallInstructions.new(dir, subdir: subdir).run
    end

    # Appends the inclusion of subdir/CMakeLists.txt
    class AppendOptionalAddSubdirectory < CMakeEditorBase
      def already_edited?
        subdir_method_call?('add_subdirectory') ||
          subdir_method_call?('ecm_optional_add_subdirectory')
      end

      def macro
        "\n" + <<-CMAKE
  include(ECMOptionalAddSubdirectory)
  ecm_optional_add_subdirectory(#{subdir})
        CMAKE
      end
    end

    # Compatibility, see AppendOptionalAddSubdirectory.
    def append_optional_add_subdirectory!(dir, subdir = nil)
      AppendOptionalAddSubdirectory.new(dir, subdir: subdir).run
    end
  end
end
