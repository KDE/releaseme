#--
# Copyright (C) 2017 Harald Sitter <sitter@kde.org>
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
