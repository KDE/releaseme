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

    # Helper, append methods can get one arg, which is expected to be a
    # path we can split into its pieces.
    # TODO: possibly deprecate calling the appends with two args altogether.
    def dir_subdir_split(dir)
      [File.dirname(dir), File.basename(dir)]
    end

    def edit_file(file)
      data = File.read(file)
      yield data
      File.write(file, data)
    end

    # Appends the install instructions for po/*
    def append_po_install_instructions!(dir, subdir = nil)
      dir, subdir = dir_subdir_split(dir) unless subdir
      macro = "\nfind_package(KF5I18n CONFIG REQUIRED)\nki18n_install(#{subdir})\n"
      edit_file("#{dir}/CMakeLists.txt") do |data|
        break if data =~ /.*#\s*SKIP_#{subdir.upcase}_INSTALL/
        if data.include?("##{subdir.upcase}_SUBDIR")
          data.sub!("##{subdir.upcase}_SUBDIR", macro)
        elsif (data =~ /^\s*(ki18n_install)\s*\(\s*#{subdir}\s*\).*$/).nil? &&
              (data =~ /^\s*(ecm_install_po_files_as_qm)\s*\(\s*#{subdir}\s*\).*$/).nil?
          data << macro
        end
      end
    end

    # Appends the install instructions for poqm/*
    def append_poqm_install_instructions!(dir, subdir = nil)
      dir, subdir = dir_subdir_split(dir) unless subdir
      macro = "\necm_install_po_files_as_qm(#{subdir})\n"
      edit_file("#{dir}/CMakeLists.txt") do |data|
        break if data =~ /.*#\s*SKIP_#{subdir.upcase}_INSTALL/
        if data.include?("##{subdir.upcase}_SUBDIR")
          data.sub!("##{subdir.upcase}_SUBDIR", macro)
        elsif (data =~ /^\s*(ecm_install_po_files_as_qm)\s*\(\s*#{subdir}\s*\).*$/).nil?
          data << macro
        end
      end
    end

    # Appends the install instructions for documentation in po/*
    def append_doc_install_instructions!(dir, subdir = nil)
      dir, subdir = dir_subdir_split(dir) unless subdir
      macro = "\nfind_package(KF5DocTools CONFIG)\nif(KF5DocTools_FOUND)\n  kdoctools_install(#{subdir})\nendif()\n"
      edit_file("#{dir}/CMakeLists.txt") do |data|
        break if data =~ /.*#\s*SKIP_#{subdir.upcase}_INSTALL/
        if data.include?("##{subdir.upcase}_SUBDIR")
          data.sub!("##{subdir.upcase}_SUBDIR", macro)
        elsif (data =~ /^\s*(kdoctools_install)\s*\(\s*#{subdir}\s*\).*$/).nil?
          data << macro
        end
      end
    end

    # Appends the inclusion of subdir/CMakeLists.txt
    def append_optional_add_subdirectory!(dir, subdir = nil)
      dir, subdir = dir_subdir_split(dir) unless subdir
      macro = "\ninclude(ECMOptionalAddSubdirectory)\necm_optional_add_subdirectory(#{subdir})\n"
      edit_file("#{dir}/CMakeLists.txt") do |data|
        break if data =~ /.*#\s*SKIP_#{subdir.upcase}_INSTALL/
        if data.include?("##{subdir.upcase}_SUBDIR")
          data.sub!("##{subdir.upcase}_SUBDIR", macro)
        elsif (data =~ /^\s*(add_subdirectory|ecm_optional_add_subdirectory)\s*\(\s*#{subdir}\s*\).*$/).nil?
          # TODO: needs test case
          # Mighty fancy regex looking for existing add_subdir.
          # Basically allows spaces everywhere one might want to put spaces.
          # At the end we allow everything as there may be a comment for example.
          data << macro
        end
      end
    end
  end
end
