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
require 'pathname'

require_relative 'logable'

# General purpose CMakeLists.txt editing functions
module CMakeEditor
  include Logable

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

  # FIXME: INSTALL_DEST needs to take into account subdirs of language
  #        e.g. kcontrol/foo/ must install to language/kcontrol/foo/
  def create_handbook(language, subdir)
    <<-EOF
kdoctools_create_handbook(index.docbook
                          INSTALL_DESTINATION \${HTML_INSTALL_DIR}/#{language}
                          SUBDIR #{subdir})\n
    EOF
  end

  # FIXME: this is getting an awful many arguments
  def write_handbook(dir, language, subdir)
    p " --- Writing #{dir}/CMakeLists.txt for #{language} :: #{subdir}"
    File.write("#{dir}/CMakeLists.txt",
               create_handbook(language, subdir))
  end

  # Creates the CMakeLists.txt for doc/$LANG/*
  # FIXME: don't overwrite en_US' CMakeLists.txt for a given subdir
  def create_language_specific_doc_lists!(dir, language, software_name)
    if File.exist?("#{dir}/index.docbook")
      # When there is an index.docbook we mustn't copy the en_US version as
      # we have to write our own CMakeLists in order to have things installed
      # in the correct language directory! Also see kdoctools_create_handbook
      # arguments.
      write_handbook(dir, language, software_name)
    elsif !Dir.glob("#{dir}/*").select { |f| File.directory?(f) }.empty?
      # -- Recyle en_US' CMakeLists --
      enusdir = "#{dir}/../en_US/"
      enuscmake = "#{enusdir}/CMakeLists.txt"
      if File.exist?(enuscmake)
        # FIXME: naughty
        FileUtils.cp(enuscmake, dir) unless File.basename(dir) == 'en_US'
        Dir.glob("#{dir}/**/**").each do |current_dir|
          next unless File.directory?(current_dir)
          next if File.basename(dir) == 'en_US'
          dir_pathname = Pathname.new(dir)
          current_dir_pathname = Pathname.new(current_dir)
          relative_path = current_dir_pathname.relative_path_from(dir_pathname)
          # FIXME: this will fail if the cmakelists doesn't exist, which is
          #        possible but also a bit odd, not sure if we should just
          #        ignore that...
          # FIXME: has no test backing I think
          cmakefile = "#{enusdir}/#{relative_path}/CMakeLists.txt"
          FileUtils.cp(cmakefile, current_dir) if File.exist?(cmakefile)
        end
        Dir.glob("#{dir}/**/index.docbook").each do |docbook|
          # FIXME: subdir logic needs testing through documentation class
          # FIXME: this is not tested via our tests
          dirname = File.dirname(docbook)
          basename = File.basename(dirname)

          dir_pathname = Pathname.new(dir)
          p dir_pathname
          current_dir_pathname = Pathname.new(dirname)
          p current_dir_pathname
          relative_path = current_dir_pathname.relative_path_from(dir_pathname)
          p relative_path
          # relative_path = '' if relative_path.to_s == basename
          p relative_path

          subdir = File.join(relative_path)
          subdir.chomp!(File::SEPARATOR)
          # FIXME: no test backing
          write_handbook(dirname, language, subdir)
        end
      else
        fail 'there is no cmakelists in enUS and also no index.docbook'
      end
    else
      fail 'There is no index.docbook but also no directories'
    end

    # en_US may already have a super cmakelists, do not twiddle with it!
    log_debug "Writing main cmakelists #{dir}/../CMakeLists.txt"
    File.open("#{dir}/../CMakeLists.txt", 'a') do |f|
      f.write(add_subdirectory(dir))
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
