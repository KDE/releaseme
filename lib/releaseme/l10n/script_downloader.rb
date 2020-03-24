#--
# Copyright (C) 2017-2019 Harald Sitter <sitter@kde.org>
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

module ReleaseMe
  # https://techbase.kde.org/Localization/Concepts/Transcript
  # Downloads scripted l10n helpers.
  class L10nScriptDownloader
    attr_reader :artifacts

    attr_reader :lang
    attr_reader :tmpdir

    # Caches available scripts for template (i.e. po file).
    # For every template in every language we'd have to do vcs.get the cache
    # does a vcs.list for each language exactly once. It records the directories
    # available so that we later can do a fast lookup and skip vcs.get
    # altogether. With each svn request taking ~1 second that is a huge
    # time saver.
    class TemplateCache
      def initialize(l10n)
        @data = {}
        @l10n = l10n

        queue = l10n.languages_queue
        threads = each_thread do
          loop_queue(queue)
        end
        threads.each(&:join)
      end

      def [](*args)
        @data[*args]
      end

      private

      attr_reader :l10n

      def loop_queue(queue)
        loop do
          lang = begin
            queue.pop(true)
          rescue
            break # loop empty if an exception was raised
          end
          @data[lang] = list(lang) # GIL secures this.
        end
      end

      def each_thread
        threads = []
        l10n.class::THREAD_COUNT.times do
          threads << Thread.new do
            Thread.current.abort_on_exception = true
            yield
          end
        end
        threads
      end

      def list(lang)
        list = l10n.vcs.list(script_file_dir(lang, l10n.i18n_path))
        list.split($INPUT_RECORD_SEPARATOR).collect do |x|
          x.delete('/')
        end
      end

      def script_file_dir(lang, i18n_path)
        "#{lang}/scripts/#{i18n_path}"
      end
    end

    def initialize(lang, tmpdir, cache, l10n)
      @lang = lang
      @tmpdir = tmpdir
      @scripts_dir = "#{tmpdir}/scripts"
      @l10n = l10n
      @artifacts = []
      @cache = cache
    end

    def download
      templates.each do |template|
        name = File.basename(template, '.po')
        next unless @cache[lang].include?(name)
        target_dir = "#{@scripts_dir}/#{name}"
        @l10n.vcs.get(target_dir, "#{script_file_dir}/#{name}", clean: true)
        unless Dir.glob("#{target_dir}/*").select { |f| File.file?(f) }.empty?
          @artifacts = [@scripts_dir]
        end
      end

      @artifacts
    end

    private

    def templates
      @l10n.templates
    end

    def script_file_dir
      "#{lang}/scripts/#{@l10n.i18n_path}"
    end
  end
end
