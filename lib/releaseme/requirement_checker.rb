#--
# Copyright (C) 2015-2017 Harald Sitter <sitter@kde.org>
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

# NB: cannot use other files as everything else is meant to load this first.
require_relative 'silencer'

module ReleaseMe
  # Makes sure the runtime requirements of releasme are met.
  class RequirementChecker
    # Finds executables. MakeMakefile is the only core ruby entity providing
    # PATH based executable lookup, unfortunately it is really not meant to be
    # used outside extconf.rb use cases as it mangles the main name scope by
    # injecting itself into it (which breaks for example the ffi gem).
    # The Shell interface's command-processor also has lookup code but it's not
    # Windows compatible.
    class Executable
      attr_reader :bin

      def initialize(bin)
        @bin = bin
      end

      # Finds the executable in PATH by joining it with all parts of PATH and
      # checking if the resulting absolute path exists and is an executable.
      # This also honor's Windows' PATHEXT to determine the list of potential
      # file extensions. So find('gpg2') will find gpg2 on POSIX and gpg2.exe
      # on Windows.
      def find
        # PATHEXT on Windows defines the valid executable extensions.
        exts = ENV.fetch('PATHEXT', '').split(';')
        # On other systems we'll work with no extensions.
        exts << '' if exts.empty?

        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          path = unescape_path(path)
          exts.each do |ext|
            file = File.join(path, bin + ext)
            return file if executable?(file)
          end
        end

        nil
      end

      private

      def executable?(path)
        stat = File.stat(path)
      rescue SystemCallError
      else
        return true if stat.file? && stat.executable?
      end

      def mswin?
        @mswin ||= /mswin/ =~ RUBY_PLATFORM
      end

      def mingw?
        @mingw ||= /mingw/ =~ RUBY_PLATFORM
      end

      def windows?
        @windows ||= ENV['RELEASEME_FORCE_WINDOWS'] || mswin? || mingw?
      end

      def unescape_path(path)
        # Strip qutation.
        # NB: POSIX does not define any quoting mechanism so you simply cannot
        # have colons in PATH on POSIX systems as a side effect we mustn't
        # strip quotes as they have no syntactic meaning and instead are
        # assumed to be part of the path
        # http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap08.html#tag_08_03
        return path.sub(/\A"(.*)"\z/m, '\1') if windows?
        path
      end
    end

    # NOTE: The versions are restricted upwards because behavior changes in the
    # language can result in unexpected outcome when using releaseme. i.e.
    # you may end up with a broken or malformed tar. To prevent this, a change
    # here must be followed by running `rake test` to pass the entire test suite
    # Also see the section on bumping versions in the REAMDE.
    COMPATIBLE_RUBIES = %w[2.1.0 2.2.0 2.3.0 2.4.0 2.5.0].freeze
    REQUIRED_BINARIES = %w[svn git tar xz msgfmt gpg2].freeze

    def initialize
      @ruby_version = RUBY_VERSION
    end

    def check
      raise 'Not all requirements met.' unless check_ruby && check_binaries
    end

    private

    def check_ruby
      return true if ruby_compatible?
      print "- Ruby #{COMPATIBLE_RUBIES.join(' or ')} required."
      print "  Currently using: #{@ruby_version}"
      false
    end

    def check_binaries
      missing_binaries.each do |m|
        print "- Missing binary: #{m}."
      end.empty?
    end

    def print(*args)
      return if Silencer.shutup?
      puts(*args)
    end

    def ruby_compatible?
      COMPATIBLE_RUBIES.each do |v|
        return true if compatible?(v)
      end
      false
    end

    def missing_binaries
      missing_binaries = []
      REQUIRED_BINARIES.each do |r|
        missing_binaries << missing?(r)
      end
      missing_binaries.compact
    end

    def compatible?(a)
      Gem::Dependency.new('', "~> #{a}").match?('', @ruby_version)
    end

    def missing?(bin)
      return bin unless Executable.new(bin).find
      nil
    end
  end
end
