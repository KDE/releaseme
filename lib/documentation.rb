#--
# Copyright (C) 2007-2015 Harald Sitter <sitter@kde.org>
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

require_relative 'cmakeeditor'
require_relative 'logable'
require_relative 'source'
require_relative 'svn'
require_relative 'translationunit'

class DocumentationL10n < TranslationUnit
  prepend Logable

  def vcs_l10n_path(lang)
    "#{lang}/docs/#{@i18n_path}/#{@project_name}"
  end

  def get(source_dir)
    dir = "#{Dir.pwd}/#{source_dir}/doc"
    temp_dir = "#{Dir.pwd}/#{source_dir}/l10n"
    Dir.mkdir(dir) unless File.exist?(dir)

    languages = vcs.cat('subdirs').split($RS)
    docs = []

    log_info "Downloading documentations for #{source_dir}"

    # On git a layout doc/{file,file,file} may appear, in this case we move
    # stuff to en_US.
    # A more complicated case would be doc/{dir,dir}/{file,file} which can
    # happen for multisource repos such as plasma-workspace.
    unless Dir.glob("#{dir}/**/index.docbook").empty? ||
           File.exist?("#{dir}/en_US")
      files = Dir.glob("#{dir}/*").uniq
      Dir.mkdir("#{dir}/en_US")
      FileUtils.mv(files, "#{dir}/en_US")
      docs << 'en_US' # We created an en_US, make sure it is in the list.
    end

    # No documentation avilable -> leave me alone
    unless File.exist?("#{dir}/en_US")
      log_warn 'There is no en_US documentation. Aborting :('
      return
    end

    CMakeEditor.create_language_specific_doc_lists!("#{dir}/en_US", 'en_US', project_name)
    languages_without_documentation = []
    languages.each do |language|
      language.chomp!
      # FIXME: this really should be filtered when the array is created...
      next if language == 'x-test' || language == 'en_US'

      FileUtils.rm_rf(temp_dir)

      doc_dirs = Dir.chdir("#{dir}/en_US") do
        Dir.glob('*').select { |f| File.directory?(f) }
      end

      dest_dir = "#{dir}/#{language}"
      done = false

      unless doc_dirs.empty?
        # FIXME: recyle for single-get?
        # FIXME: check cmake file for add_subdir that are not optional and warn if there are any
        vcs.get(temp_dir, "#{language}/docs/#{@i18n_path}")
        not_translated_doc_dirs = doc_dirs.clone
        doc_selection = Dir.glob("#{temp_dir}/*").select do |d|
          basename = File.basename(d)
          if doc_dirs.include?(basename)
            not_translated_doc_dirs.delete(basename)
            next true
          end
          next false
        end
        if doc_selection.empty?
          languages_without_documentation << language
          next
        end
        Dir.mkdir(dest_dir) # Important otherwise first copy is dir itself...
        doc_selection.each do |d|
          FileUtils.mv(d, dest_dir)
        end
        CMakeEditor.create_language_specific_doc_lists!(dest_dir, language, project_name)
        docs << language
        done = true
      end
      unless done
        # FIXME this also needs to act as fallback
        vcs.get(temp_dir, vcs_l10n_path(language))
        unless FileTest.exist?("#{temp_dir}/index.docbook")
          languages_without_documentation << language
          next
        end

        FileUtils.mv(temp_dir, dest_dir)
        CMakeEditor.create_language_specific_doc_lists!("#{dir}/#{language}", language, project_name)

        # add to SVN in case we are tagging
        # FIXME: direct svn access
        # `svn add #{dir}/#{language}/CMakeLists.txt`
        docs += [language]
      end
    end

    if !docs.empty?
      CMakeEditor.create_doc_meta_lists!(dir)
      CMakeEditor.append_optional_add_subdirectory!(source_dir, 'doc')
    else
      log_warn 'There are no translations at all!'
      FileUtils.rm_rf(dir)
    end

    FileUtils.rm_rf(temp_dir)

    log_info "No translations for: #{languages_without_documentation.join(', ')}" unless languages_without_documentation.empty?
  end
end
