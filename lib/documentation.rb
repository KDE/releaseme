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
require 'thwait'

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

  def get(srcdir)
    dir = "#{Dir.pwd}/#{srcdir}/doc"
    Dir.mkdir(dir) unless File.exist?(dir)

    languages = vcs.cat('subdirs').split($RS)
    docs = []

    log_info "Downloading documentations for #{srcdir}"

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

    queue = Queue.new
    languages.each do |language|
      next if language == 'x-test' || language == 'en_US'
      p language
      queue << language
    end

    threads = []
    THREAD_COUNT.times do
      threads << Thread.new do
        until queue.empty?
          language = queue.pop(true)
            Dir.mktmpdir(self.class.to_s) do |tmpdir|
              begin
                # FIXME: this really only should be computed once
                doc_dirs = Dir.glob("#{dir}/en_US/*").collect do |f|
                  next nil unless File.directory?(f)
                  File.basename(f)
                end
                doc_dirs.compact!

                dest_dir = "#{dir}/#{language}"
                done = false
                log_info doc_dirs
                unless doc_dirs.empty?
                  # FIXME: recyle for single-get?
                  # FIXME: check cmake file for add_subdir that are not optional and warn if there are any
                  vcs.get(tmpdir, "#{language}/docs/#{@i18n_path}")
                  not_translated_doc_dirs = doc_dirs.clone
                  # FIXME: for some reason with plasma-desktop /* didn't work
                  #        yet the tests passed, so the tests seem insufficient
                  p Dir.glob("#{tmpdir}/**")
                  doc_selection = Dir.glob("#{tmpdir}/**").select do |d|
                    basename = File.basename(d)
                    p basename
                    if doc_dirs.include?(basename)
                      not_translated_doc_dirs.delete(basename)
                      p 'true'
                      next true
                    end
                    p 'false'
                    next false
                  end
                  if doc_selection.empty?
                    p 'doc_selection empty'
                    languages_without_documentation << language
                    next
                  end
                  Dir.mkdir(dest_dir) # Important otherwise first copy is dir itself...
                  doc_selection.each do |d|
                    FileUtils.mv(d, dest_dir)
                  end
                  CMakeEditor.create_language_specific_doc_lists!(dest_dir, language, project_name)
                  # FIXME: not threadsafe without GIL
                  docs << language
                  done = true
                end
                unless done
                  # FIXME this also needs to act as fallback
                  vcs.get(tmpdir, vcs_l10n_path(language))
                  unless FileTest.exist?("#{tmpdir}/index.docbook")
                    languages_without_documentation << language
                    next
                  end

                  FileUtils.mv(tmpdir, dest_dir)
                  CMakeEditor.create_language_specific_doc_lists!("#{dir}/#{language}", language, project_name)

                  # FIXME: not threadsafe without GIL
                  docs += [language]
                end

              rescue => e
                p e
                log_fail e
                p e
                exit 1
              end
            end
        end
      end
    end
    ThreadsWait.all_waits(threads)

    if !docs.empty?
      CMakeEditor.create_doc_meta_lists!(dir)
      CMakeEditor.append_optional_add_subdirectory!(srcdir, 'doc')
    else
      log_warn 'There are no translations at all!'
      FileUtils.rm_rf(dir)
    end

    return if languages_without_documentation.empty?
    log_info "No translations for: #{languages_without_documentation.join(', ')}"
  end
end
