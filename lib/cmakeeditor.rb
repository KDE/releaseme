#--
# Copyright (C) 2007-2014 Harald Sitter <apachelogger@ubuntu.com>
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

# General purpose CMakeLists.txt editing functions
module CMakeEditor
    extend self

    # Creates the CMakeLists.txt for doc/$LANG/*
    def create_language_specific_doc_lists!(dir, language, software_name)
        # In case of en_US there could be a CMakeLists already present, do not
        # overwrite it as there may be fancy logic inside.
        return if File.exist?("#{dir}/CMakeLists.txt")

        file = File.new("#{dir}/CMakeLists.txt", File::CREAT | File::RDWR | File::TRUNC)
        if File.exist?('index.docbook')
            file << "kdoctools_create_handbook(index.docbook INSTALL_DESTINATION \${HTML_INSTALL_DIR}/#{language} SUBDIR #{software_name})\n"
        else
            # FIXME: needs test
            previous_wd = Dir.pwd
            Dir.chdir(dir)
            # FIXME: shitty hardcoding
            # FIXME: this actually depends on the fact that en_US uses optional_add_subdir
            #        as otherwise languages won't build when they have no translation for a subdir.
            # Iff en_US has a CMakeLists.txt reuse it.
            if File.exist?('../en_US/CMakeLists.txt')
                file.close()
                FileUtils.cp('../en_US/CMakeLists.txt', '.')
            else
                # If there is no file in en_US, simply write one manually.
                Dir.glob('*/index.docbook').each do |docbook|
                    dirname = File.dirname(docbook)
                    # TODO: use append_optional_add_subdirectory! maybe?
                    file << "ecm_optional_add_subdirectory(#{dirname})\n"
                    # FIXME: we need more nesting here... NOT :@
                end
            end
            Dir.chdir(previous_wd)
        end
        file.close()
    end

    # Creates the CMakeLists.txt for doc/*
    def create_doc_meta_lists!(dir)
        file = File.new("#{dir}/CMakeLists.txt",
                             File::CREAT | File::RDWR | File::TRUNC)
        Dir.foreach(dir) do |lang|
            next if lang == '.' or lang == '..' or lang == 'CMakeLists.txt'
            file << "add_subdirectory(#{lang})\n"
        end
        file.close
    end

    # Creates the CMakeLists.txt for po/$LANG/*.po
    def create_language_specific_po_lists!(dir, language)
        file = File.new("#{dir}/CMakeLists.txt",
                        File::CREAT | File::RDWR | File::TRUNC)
        file << "file(GLOB _po_files *.po)\n"
        file << "GETTEXT_PROCESS_PO_FILES(#{language} ALL INSTALL_DESTINATION ${LOCALE_INSTALL_DIR} ${_po_files})\n"
        file.close
    end

    # Creates the CMakeLists.txt for po/*
    def create_po_meta_lists!(dir)
        file = File.new("#{dir}/CMakeLists.txt",
                             File::CREAT | File::RDWR | File::TRUNC)
        file.write <<-EOF
# The pofiles macro creates in some versions same name targets
# which since cmake 2.8 leads to target clashes.
# Hence force the old policy for all po directories.
# http://public.kitware.com/Bug/view.php?id=12952
cmake_policy(SET CMP0002 OLD)

find_package(Gettext REQUIRED)
if (NOT GETTEXT_MSGMERGE_EXECUTABLE)
MESSAGE(FATAL_ERROR "Please install msgmerge binary")
endif (NOT GETTEXT_MSGMERGE_EXECUTABLE)
if (NOT GETTEXT_MSGFMT_EXECUTABLE)
MESSAGE(FATAL_ERROR "Please install msgmerge binary")
endif (NOT GETTEXT_MSGFMT_EXECUTABLE)
        EOF
        Dir.foreach(dir) do |lang|
            next if lang == '.' or lang == '..' or lang == 'CMakeLists.txt'
            file << "add_subdirectory(#{lang})\n"
        end
        file.close
    end

    # Appends the inclusion of po/CMakeLists.txt
    def append_optional_add_subdirectory!(dir, subdir)
        file = File.new("#{dir}/CMakeLists.txt", File::APPEND | File::RDWR )
        data = file.read()
        file.rewind()
        file.truncate( 0 )
        macro = "\ninclude(ECMOptionalAddSubdirectory)\necm_optional_add_subdirectory(#{subdir})\n"
        if data.include?("##{subdir.upcase}_SUBDIR")
            data = data.sub("##{subdir.upcase}_SUBDIR",macro)
        elsif (data =~ /^\s*(add_subdirectory|ecm_optional_add_subdirectory)\s*\(\s*#{subdir}\s*\).*$/).nil?
            # TODO: needs test case
            # Mighty fancy regex looking for existing add_subdir.
            # Basically allows spaces everywhere one might want to put spaces.
            # At the end we allow everything as there may be a comment for example.
            data << macro
        end
        file << data
        file.close
    end

private
end
