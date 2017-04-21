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

module ReleaseMe
  class DocumentationL10n < TranslationUnit
    prepend Logable

    def vcs_l10n_path(lang)
      "#{lang}/docs/#{@i18n_path}/#{@project_name}"
    end

    def get(srcdir)
      # TODO: instead of moving the trees around, checkout into /po. This should
      # simplify the actual logic a bit. There is however the fairly silly use
      # case of CMakeLists re-use to be considered. i.e. if a source has
      # multiple docbooks and some of them are dependent on build-time
      # configuration it would be weird if those docbooks got installed all the
      # time for $lang while the native english docs are flag sensitive.
      @docdir = "#{File.expand_path(srcdir)}/doc"
      FileUtils.mkpath(@docdir)

      docs = []
      languages_without_documentation = []

      log_info "Downloading documentations for #{srcdir}"

      unless get_en('en')
        log_warn 'There is no en documentation. Skipping documentation :('
        FileUtils.rmdir(@docdir)
        return
      end
      docs << 'en'

      queue = languages_queue(%w(en))
      threads = []
      THREAD_COUNT.times do
        threads << Thread.new do
          Thread.current.abort_on_exception = true
          until queue.empty?
            language = queue.pop(true)
            if get_language(language)
              docs << language
            else
              languages_without_documentation << language
            end
          end
        end
      end
      ThreadsWait.all_waits(threads)

      if !docs.empty?
        CMakeEditor.create_doc_meta_lists!(@docdir)
        CMakeEditor.append_optional_add_subdirectory!(@docdir)
      else
        log_warn 'There are no translations at all!'
        FileUtils.rm_rf(@docdir)
      end

      return if languages_without_documentation.empty?
      log_info "No translations for: #{languages_without_documentation.join(', ')}"
    end

    private

    def doc_dirs
      # FIXME: this could be put in the class instance assuming we never want to
      #        have different projects in the same ruby instance
      return @doc_dirs if defined? @doc_dirs
      @doc_dirs = Dir.glob("#{@docdir}/en/*").collect do |f|
        next nil unless File.directory?(f)
        File.basename(f)
      end
      @doc_dirs = @doc_dirs.compact
    end

    def get_en(language)
      # FIXME: code dup from regular get
      destdir = "#{@docdir}/#{language}"

      # On git a layout doc/{file,file,file} may appear, in this case we move
      # stuff to en.
      # A more complicated case would be doc/{dir,dir}/{file,file} which can
      # happen for multisource repos such as plasma-workspace.
      unless Dir.glob("#{@docdir}/**/index.docbook").empty? ||
             File.exist?(destdir)
        list = Dir.glob("#{@docdir}/*").uniq
        FileUtils.mkpath(destdir)
        FileUtils.mv(list, destdir)
      end
      if File.exist?(destdir)
        CMakeEditor.create_language_specific_doc_lists!(destdir, language, @project_name)
        return true
      end
      false
    end

    def get_language(language)
      destdir = "#{@docdir}/#{language}"

      Dir.mktmpdir(self.class.to_s) do |tmpdir|
        unless doc_dirs.empty?
          # FIXME: recyle for single-get?
          # FIXME: check cmake file for add_subdir that are not optional and warn if there are any
          @vcs.get(tmpdir, "#{language}/docs/#{@i18n_path}")

          not_translated_doc_dirs = doc_dirs
          # FIXME: for some reason with plasma-desktop /* didn't work
          #        yet the tests passed, so the tests seem insufficient
          doc_selection = Dir.glob("#{tmpdir}/**").select do |d|
            basename = File.basename(d)
            if doc_dirs.include?(basename)
              not_translated_doc_dirs.delete(basename)
              next true
            end
            next false
          end
          break if doc_selection.empty?

          FileUtils.mkpath(destdir)
          doc_selection.each { |d| FileUtils.mv(d, destdir) }
          CMakeEditor.create_language_specific_doc_lists!(destdir, language, @project_name)
          return true
        end

        @vcs.get(tmpdir, vcs_l10n_path(language))
        return false unless FileTest.exist?("#{tmpdir}/index.docbook")

        FileUtils.mkpath(destdir)
        FileUtils.cp_r(Dir.glob("#{tmpdir}/*"), destdir)
        CMakeEditor.create_language_specific_doc_lists!(destdir, language, @project_name)
      end
      true
    end
  end
end
