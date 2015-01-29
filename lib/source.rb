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

require 'fileutils'

class Source
  # The target directory
  attr_accessor :target

  # Cleans the source for archiving (e.g. removes .git directory).
  def clean(vcs)
    vcs.clean!(target)
  end

  # Cleans up data created
  def cleanup()
    FileUtils.rm_rf(target)
  end

  # Gets the source
  def get(vcs, shallow = true)
    # FIXME: this is a bloody warkaround for the fact that vcs itself
    #        doesn't actually know about shallows, but git does and
    #        for tarme shallow is desirable whereas for tagme we need a full
    #        clone....
    #        perhaps a bool:shallow attribute on the vcs would help?
    begin
      vcs.get(target, shallow)
    rescue
      vcs.get(target)
    end
  end

end
