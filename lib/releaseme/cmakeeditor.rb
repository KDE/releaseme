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
      log_debug " --- Writing #{dir}/CMakeLists.txt for #{language} :: #{subdir}"
      File.write("#{dir}/CMakeLists.txt", create_handbook(language, subdir))
    end

    # Creates the CMakeLists.txt for doc/$LANG/*
    # FIXME: don't overwrite en' CMakeLists.txt for a given subdir
    def create_language_specific_doc_lists!(dir, language, software_name)
      if File.exist?("#{dir}/index.docbook")
        # When there is an index.docbook we mustn't copy the en version as
        # we have to write our own CMakeLists in order to have things installed
        # in the correct language directory! Also see kdoctools_create_handbook
        # arguments.
        write_handbook(dir, language, software_name)
      elsif !Dir.glob("#{dir}/*").select { |f| File.directory?(f) }.empty?
        # -- Recyle en' CMakeLists --
        enusdir = "#{dir}/../en/"
        enuscmake = "#{enusdir}/CMakeLists.txt"
        if File.exist?(enuscmake)
          # FIXME: naughty
          FileUtils.cp(enuscmake, dir) unless File.basename(dir) == 'en'
          Dir.glob("#{dir}/**/**").each do |current_dir|
            next unless File.directory?(current_dir)
            next if File.basename(dir) == 'en'
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

            dir_pathname = Pathname.new(dir)
            current_dir_pathname = Pathname.new(dirname)
            relative_path = current_dir_pathname.relative_path_from(dir_pathname)

            subdir = File.join(relative_path)
            subdir.chomp!(File::SEPARATOR)
            # FIXME: really naughty workaround to avoid overwriting existing lists
            unless language == 'en' && File.exist?("#{dirname}/CMakeLists.txt")
              # FIXME: no test backing
              write_handbook(dirname, language, subdir)
            end
          end
        else
          raise 'there is no cmakelists in enUS and also no index.docbook'
        end
      else
        raise 'There is no index.docbook but also no directories'
      end

      # en may already have a super cmakelists, do not twiddle with it!
      log_debug "Writing main cmakelists #{dir}/../CMakeLists.txt"
      # FIXME: not thread safe
      File.open("#{dir}/../CMakeLists.txt", 'a') do |f|
        f.write(add_subdirectory(dir, relative_to: "#{dir}/.."))
      end
    end

    # Creates the CMakeLists.txt for doc/*
    def create_doc_meta_lists!(dir)
      file = File.new("#{dir}/CMakeLists.txt", 'w')
      Dir.foreach(dir) do |lang|
        next if %w(. .. CMakeLists.txt).include?(lang)
        file << "add_subdirectory(#{lang})\n"
      end
      file.close
    end

    # Appends the install instructions for po/*
    def append_po_install_instructions!(dir, subdir)
      file = "#{dir}/CMakeLists.txt"
      data = File.read(file)
      macro = "\nfind_package(KF5I18n CONFIG REQUIRED)\nki18n_install(#{subdir})\n"
      if data.include?("##{subdir.upcase}_SUBDIR")
        data = data.sub("##{subdir.upcase}_SUBDIR", macro)
      elsif (data =~ /^\s*(ki18n_install)\s*\(\s*#{subdir}\s*\).*$/).nil? &&
            (data =~ /^\s*(ecm_install_po_files_as_qm)\s*\(\s*#{subdir}\s*\).*$/).nil?
        data << macro
      end
      File.write(file, data)
    end

    # Appends the install instructions for poqm/*
    def append_poqm_install_instructions!(dir, subdir)
      file = "#{dir}/CMakeLists.txt"
      data = File.read(file)
      macro = "\necm_install_po_files_as_qm(#{subdir})\n"
      if data.include?("##{subdir.upcase}_SUBDIR")
        data = data.sub("##{subdir.upcase}_SUBDIR", macro)
      elsif (data =~ /^\s*(ecm_install_po_files_as_qm)\s*\(\s*#{subdir}\s*\).*$/).nil?
        data << macro
      end
      File.write(file, data)
    end

    # Appends the inclusion of subdir/CMakeLists.txt
    def append_optional_add_subdirectory!(dir, subdir)
      file = "#{dir}/CMakeLists.txt"
      data = File.read(file)
      macro = "\ninclude(ECMOptionalAddSubdirectory)\necm_optional_add_subdirectory(#{subdir})\n"
      if data.include?("##{subdir.upcase}_SUBDIR")
        data = data.sub("##{subdir.upcase}_SUBDIR", macro)
      elsif (data =~ /^\s*(add_subdirectory|ecm_optional_add_subdirectory)\s*\(\s*#{subdir}\s*\).*$/).nil?
        # TODO: needs test case
        # Mighty fancy regex looking for existing add_subdir.
        # Basically allows spaces everywhere one might want to put spaces.
        # At the end we allow everything as there may be a comment for example.
        data << macro
      end
      File.write(file, data)
    end
  end
end
