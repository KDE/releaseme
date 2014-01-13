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

require_relative 'git'
require_relative 'source'
require_relative 'xzarchive'

class KdeGitRelease
    # The vcs from which to get the source
    attr_reader :vcs
    # The source object from which the release is done
    attr_reader :source
    # The archive object which will create the archive
    attr_reader :archive

    # Init
    def initialize()
        @vcs = Git.new()
        @source = Source.new()
        @archive = XzArchive.new()
    end

    # Get the source
    def get()
        source.cleanup()
        source.get(vcs)
    end

    # Create the final archive file
    def archive()
        source.clean(vcs)
        @archive.directory = source.target
        @archive.create()
    end

end
