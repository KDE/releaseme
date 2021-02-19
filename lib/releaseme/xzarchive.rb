# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2007-2017 Harald Sitter <sitter@kde.org>

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
             'tar', '--format=gnu', '--owner=kde', '--group=kde', '-cJf', xz, dir,
             %i[out] => File::NULL) || raise
      @filename = xz
      @path = File.realpath(xz)
    end
  end
end
