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
  module_function

=begin
  -git-

    doc/CMakeLists.txt
    doc/index.docbook
    doc/...

      -> move doc/* to doc/en_US/*
      -> get_translations_single
      -> if translation && index.docbook -> move to doc/language/*
        -> write a cmake file for doc/language/
      -> write a cmake file doc/
      -> add doc to main cmakelists

    doc/CMakeLists.txt
    doc/directory1/CMakeLists.txt
    doc/directory1/index.docbook
    doc/directory1/...
    doc/directory2/CMakeLists.txt
    doc/directory2/index.docbook
    doc/directory2/...
    doc/directory3/index.docbook                  [invalid?]
    doc/directory4/CMakeLists.txt                 [invalid!]

      -> move doc/* to doc/en_US/*
      -> get_translatins_multi
        -> get whole component-module dir
        -> foreach en_USdir[that has an index.docbook] do;
          -> if translation && index.docbook -> move to doc/language/dir/*
          -> write a cmake file for doc/language/dir
      -> write a cmake file for doc/language
      -> write cmake file doc/
      -> add doc to main cmakelists

    doc/en_US/CMakeLists.txt
    doc/en_US/index.docbook
    doc/en_US/...

    doc/en_US/CMakeLists.txt
    doc/en_US/directory1/...
    doc/en_US/directory2/...

    ? what if there is no CMakeLists at all

  -svn-

    component-module/project/index.docbook

    component-module/directory1/index.docbook

    component-module/directory2/index.docbook

    component/project/index.docbook

    ? what if there is no translation
=end

  def add_subdirectory(file)
    "add_subdirectory(#{File.basename(file)})\n"
  end

  def create_handbook(language, software_name)
    <<-EOF
kdoctools_create_handbook(index.docbook
                          INSTALL_DESTINATION \${HTML_INSTALL_DIR}/#{language}
                          SUBDIR #{File.basename(software_name)})\n
    EOF
  end

  def write_handbook(language, software_name)
    File.write('CMakeLists.txt', create_handbook(language, software_name))
  end

  # Creates the CMakeLists.txt for doc/$LANG/*
  # FIXME: don't overwrite en_US' CMakeLists.txt for a given subdir
  def create_language_specific_doc_lists!(dir, language, software_name)
    Dir.chdir(dir) do
      if File.exist?('index.docbook')
        # When there is an index.docbook we mustn't copy the en_US version as
        # we have to write our own CMakeLists in order to have things installed
        # in the correct language directory! Also see kdoctools_create_handbook
        # arguments.
        write_handbook(language, software_name)
      elsif !Dir.glob('*').select { |f| File.directory?(f) }.empty?
        # -- Recyle en_US' CMakeLists --
        enusdir = '../en_US/'
        enuscmake = "#{enusdir}/CMakeLists.txt"
        if File.exist?(enuscmake)
          # FIXME: naughty
          unless File.basename(Dir.pwd) == 'en_US'
            FileUtils.cp(enuscmake, '.')
          end
          Dir.glob('**/index.docbook').each do |docbook|
            dirname = File.dirname(docbook)
            Dir.chdir(dirname) do
              write_handbook(language, File.basename(dirname))
            end
          end
        else
          fail 'there is no cmakelists in enUS and also no index.docbook'
        end
      else
        fail 'There is no index.docbook but also no directories'
      end

      # en_US may already have a super cmakelists, do not twiddle with it!
      # FIXME: log
      # puts "Writing main cmakelists #{Dir.pwd}/../CMakeLists.txt"
      File.open('../CMakeLists.txt', 'a') do |f|
        f.write(add_subdirectory(dir))
      end
    end
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

    # Appends the install instructions for po/*
    def append_po_install_instructions!(dir, subdir)
        file = File.new("#{dir}/CMakeLists.txt", File::APPEND | File::RDWR )
        data = file.read()
        file.rewind()
        file.truncate(0)
        macro = "\nfind_package(KF5I18n CONFIG REQUIRED)\nki18n_install(#{subdir})\n"
        if data.include?("##{subdir.upcase}_SUBDIR")
            data = data.sub("##{subdir.upcase}_SUBDIR",macro)
        elsif (data =~ /^\s*(ki18n_install)\s*\(\s*#{subdir}\s*\).*$/).nil?
            data << macro
        end
        file << data
        file.close
    end

    # Appends the inclusion of subdir/CMakeLists.txt
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
