#--
# Copyright (C) 2014 Harald Sitter <sitter@kde.org>
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

class L10nStatistics
  attr_reader :stats

  def initialize # (project)
    # project = project
    @stats = {}
  end

  def gather!(srcdir)
    podir = "#{srcdir}/po/"
    Dir.chdir(podir) do
      languages = Dir.glob('*')
      languages.each do |language|
        next unless File.directory?(language)
        Dir.chdir(language) do
          translated = 0
          fuzzy = 0
          untranslated = 0

          Dir.glob('*.po').each do |file|
            data = `LC_ALL=C LANG=C msgfmt --statistics #{file} -o /dev/null > /dev/stdout 2>&1`

            # tear the data apart and create some variables
            data.split(',').each do |x|
              if x.include?('untranslated')
                untranslated += x.scan(/[\d]+/)[0].to_i
              elsif x.include?('fuzzy')
                fuzzy += x.scan(/[\d]+/)[0].to_i
              elsif x.include?('translated')
                translated += x.scan(/[\d]+/)[0].to_i
              end
            end
          end

          all = translated + fuzzy + untranslated
          notshown = fuzzy + untranslated
          shown = all - notshown
          percentage = ((100.0 * shown.to_f) / all.to_f)

          @stats[language] = {
            all: all,
            shown: shown,
            notshown: notshown,
            percentage: percentage
          }
        end
      end
    end
  end

  def write(_html_file_path)
  end
end
