#--
# Copyright (C) 2007-2014 Harald Sitter <apachelogger@ubuntu.com>
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

##
# Tar-XZ Archiving Class.
# This class archives @directory into an tar file and compresses it using xz.
# Compression strength is set via @level.
class XzArchive
    # The directory to archive
    attr :directory, true

    # XZ compression level (must be between 1 and 9 - other values will not
    # result in an archive file)
    attr :level, true

    # Creates new XzArchive. @directory must be assigned seperately.
    def initialize()
        @directory = nil
        @level = 9
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
    def create()
        tar = "#{directory}.tar"
        return false if not File.exists?(@directory)
        begin
            FileUtils.rm_rf(tar)
            FileUtils.rm_rf(tar + ".xz")
            # Note that system returns bool but only captures stdout.
            raise RuntimeError if not system("tar -cf #{tar} #{directory} 2> /dev/null")
            raise RuntimeError if not system("xz -#{level} #{tar} 2> /dev/null")
            return true
        rescue
            FileUtils.rm_rf(tar)
            FileUtils.rm_rf(tar + ".xz")
            return false
        end
    end
end
