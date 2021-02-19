# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2014-2019 Harald Sitter <sitter@kde.org>

require 'erb'
require 'open3'

module ReleaseMe
  # Gathers statistics on a given language directory containing po files
  # (or not).
  class LanguageStatistics
    attr_reader :valid

    attr_reader :name
    attr_reader :translated
    attr_reader :fuzzy
    attr_reader :untranslated

    attr_reader :dirs

    def initialize(name)
      @valid = false

      @name = name
      @translated = 0
      @fuzzy = 0
      @untranslated = 0

      @dirs = []
    end

    def all
      shown + notshown
    end

    def shown
      translated
    end

    def notshown
      fuzzy + untranslated
    end

    def percent_translated
      (100.0 * shown.to_f) / all.to_f
    end

    def gather(dir)
      @dirs << dir

      Dir.glob("#{dir}/*.po").each do |file|
        _, stderr, status = Open3.capture3(
          { 'LC_ALL' => 'C', 'LANG' => 'C' },
          'msgfmt', '--statistics', file, '-o', File::NULL,
        )
        raise stderr unless status.success?
        data = stderr.strip

        # tear the data apart and create some variables
        data.split(',').each do |x|
          if x.include?('untranslated')
            @untranslated += x.scan(/[\d]+/)[0].to_i
          elsif x.include?('fuzzy')
            @fuzzy += x.scan(/[\d]+/)[0].to_i
          elsif x.include?('translated')
            @translated += x.scan(/[\d]+/)[0].to_i
          end
        end

        @valid = true
      end
    end
  end

  # Dump statistics to html
  class L10nStatisticsHTMLPrinter
    def initialize(stats, release)
      @stats = stats
      @release = release
    end

    def stat_color(stat)
      {
        100 => "#00B015", #green
        95 => "#FF9900", #orange
        75 => "#6600FF", #blue
        50 => "#000000", #black
        0 => "#FF0000"  #red
      }.each do |cutoff, color|
        return color if stat.percent_translated >= cutoff
      end

      ''
    end

    def write(html_file_path)
      t = ERB.new(File.read("#{__dir__}/data/l10n_statistics.html.erb"))
      File.write(html_file_path, t.result(binding))
    end
  end

  # Gather (po) statistics on directories.
  class L10nStatistics
    attr_reader :languages

    def initialize(podirs)
      stats_by_lang = {}

      podirs.each do |podir|
        Dir.glob("#{podir}/*").each do |langdir|
          next unless File.directory?(langdir)
          lang = File.basename(langdir)

          stats_by_lang[lang] ||= LanguageStatistics.new(lang)
          stat = stats_by_lang[lang]
          stat.gather(langdir)
        end
      end

      # Only select actually valid stats. Others we have no data on and
      # pretend they don't exist.
      @languages = stats_by_lang.values.select { |x| x.valid }
      @languages = @languages.sort_by(&:name)
    end
  end
end
