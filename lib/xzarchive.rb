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

class XzArchive
    # The directory to archive
    attr :directory, true

    # XZ compression level
    attr :level, true

    def initialize()
        @directory = nil
        @level = 9
    end

    # Create the archive
    def create()
        tar = "#{directory}.tar"
        return if not File.exists?(@directory)
        begin
            raise RuntimeError if not %x[tar -cf #{tar} #{directory}]
            raise RuntimeError if not %x[xz -#{level} #{tar}]
        rescue
            FileUtils.rm_rf(tar)
            FileUtils.rm_rf(tar + ".xz")
        end
    end
end
