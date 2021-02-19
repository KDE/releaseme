# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017 Harald Sitter <sitter@kde.org>

require 'json'

require_relative 'logable'

module ReleaseMe
  class AssertionFailedError < StandardError; end

  # Asserts that a file tree does not contain case-conflicting files.
  module AssertCaseInsensitive
    prepend Logable

    class << self
      # rubocop:disable Metrics/MethodLength
      def assert(dir)
        # This obviously suffers from a bit of a flaw in that if releaseme
        # gets run on a case-insensitive FS to begin with the conflicts may
        # result in overwrites in other code (notably l10n fetching).
        # Seeing as most devs run Linux that is unlikely to happen right now,
        # but may need rectifying at some point by making all code globally
        # butt out if files were to be overwritten.
        # entries = Dir.glob("#{dir}/**/**").collect(&:downcase)
        entries = Dir.glob("#{dir}/**/**").group_by(&:downcase)
        dupes = entries.select { |_, canonical_paths| canonical_paths.size > 1 }
        return if dupes.nil? || dupes.empty?
        log_fatal <<-ERRORMSG
\n
The resulting tarball contains case-sensitive conflicting files. This makes the
tarball incompatible with case-insensitive file systems or operating systems
(e.g. Windows). This is a fatal problem and must be solved before release!
To resolve the problem the case-conflicting files and/or directories need to be
renamed so that their fully downcased representations do not conflict anymore.

e.g. src/Foo.txt and Src/foo.txt are both src/foo.txt when fully converted to
     lower case. To resolve the issue you could rename the directory Src to bar
     so you get src/Foo.txt and bar/foo.txt and they no longer conflict

The conflicting paths are:
#{JSON.pretty_generate(dupes)}
        ERRORMSG
        raise AssertionFailedError
      end
    end
  end
end
