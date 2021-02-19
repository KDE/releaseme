# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2007-2017 Harald Sitter <sitter@kde.org>

require 'delegate'

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
