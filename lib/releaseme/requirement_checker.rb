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
    # NOTE: The versions are restricted upwards because behavior changes in the
    # language can result in unexpected outcome when using releaseme. i.e.
    # you may end up with a broken or malformed tar. To prevent this, a change
    # here must be followed by running `rake test` to pass the entire test suite!
    # Also see the section on bumping versions in the REAMDE.
    COMPATIBLE_RUBIES = %w[2.1.0 2.2.0 2.3.0 2.4.0].freeze
    REQUIRED_BINARIES = %w[svn git tar xz msgfmt gpg2].freeze

    def initialize
      @ruby_version = RUBY_VERSION
    end

    def check
      err = false
      unless ruby_compatible?
        print "- Ruby #{COMPATIBLE_RUBIES.join(' or ')} required."
        print "  Currently using: #{@ruby_version}"
        err = true
      end
      missing_binaries.each do |m|
        print "- Missing binary: #{m}."
        err = true
      end
      raise 'Not all requirements met.' if err
    end

    private

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
        missing_binaries << missing(r)
      end
      missing_binaries.compact
    end

    def compatible?(a)
      Gem::Dependency.new('', "~> #{a}").match?('', @ruby_version)
    end

    def missing(bin)
      return bin unless system("type #{bin} > /dev/null 2>&1")
      nil
    end
  end
end
