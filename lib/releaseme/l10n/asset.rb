#--
# Copyright (C) 2007-2017 Harald Sitter <sitter@kde.org>
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
  # Wraps around an asset file (pofile, script, whathaveyou) to allow
  # streamlined handling of files.
  class L10nAsset < DelegateClass(String)
    def initialize(path)
      super(File.absolute_path(path))
    end

    def strip!
      return unless po?
      strip_comments!
    end

    def qt?
      File.basename(self).end_with?('_qt.po')
    end

    private

    def po?
      end_with?('.po')
    end

    def strip_comments!
      # Strip #~ lines, which once were sensible translations, but then the
      # strings got removed, so they now stick around in case the strings
      # return, poor souls, waiting for a comeback, reminds me of Sunset Blvd :(
      # Problem is that msgfmt adds those to the binary!
      file = File.new(self, File::RDWR)
      str = file.read
      file.rewind
      file.truncate(0)
      # Sometimes a fuzzy marker can precede an obsolete translation block, so
      # first remove any fuzzy obsoletion in the file and then remove any
      # additional obsoleted lines.
      # This prevents the fuzzy markers from getting left over.
      str.gsub!(/^#, fuzzy\n#~.*/, '')
      str.gsub!(/^#~.*/, '')
      str = str.strip
      file << str
      file.close
    end
  end
end
