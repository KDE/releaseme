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

require_relative 'assert_case_insensitive'

module ReleaseMe
  ##
  # Tar-XZ Archiving Class.
  # This class archives @directory into an tar file and compresses it using xz.
  # Compression strength is set via @level.
  class XzArchive
    # The directory to archive
    attr_accessor :directory

    # XZ compression level (must be between 1 and 9 - other values will not
    # result in an archive file)
    attr_accessor :level

    # XZ compressed tarball file name (e.g. foobar-1.tar.xz)
    # This is nil unless create() finished successfully.
    attr_reader :filename

    # @return String absolute path of archive file
    attr_reader :path

    LEVEL_RANGE = 0..9

    # Creates new XzArchive. @directory must be assigned separately.
    def initialize
      @directory = nil
      @level = 9
      @filename = nil
      @path = nil
    end

    ##
    # call-seq:
    #  archive.create() -> true or false
    #
    # Create the archive. Creates an archive based on the directory attribute.
    # Results in @directory.tar.xz in the present working directory.
    #--
    # FIXME: need routine to run and log a) command b) results c) outputs
    #++
    def create
      xz = "#{directory}.tar.xz"
      return false unless valid?
      FileUtils.rm_rf(xz)
      # Note that system returns bool but only captures stdout.
      compress(directory, xz) || raise
      return true
    rescue RuntimeError
      FileUtils.rm_rf(xz)
      return false
    end

    private

    def valid?
      File.exist?(@directory) && LEVEL_RANGE.include?(@level) && asserts
    end

    def asserts
      AssertCaseInsensitive.assert(@directory)
      true # Included in && chain.
    end

    def compress(dir, xz)
      # Tar and compress in one go. tar supports -J for quite a while now.
      system({ 'XZ_OPT' => "-#{level}" },
             'tar', 'cfJ', xz, dir,
             %i[out] => File::NULL) || raise
      @filename = xz
      @path = File.realpath(xz)
    end
  end
end
