#--
# Copyright (C) 2017 Harald Sitter <apachelogger@ubuntu.com>
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

module ReleaseMe
  module Origin
    # The symbolic values should not ever be changed as they may be hardcoded or
    # converted to/from strings representation with outside sources.
    TRUNK = :trunk # technicall _kf5
    STABLE = :stable
    LTS = :lts
    TRUNK_KDE4 = :trunk_kde4
    STABLE_KDE4 = :stable_kde4

    ALL = [TRUNK, STABLE, LTS, TRUNK_KDE4, STABLE_KDE4].freeze

    module_function

    def kde4?(origin)
      [TRUNK_KDE4, STABLE_KDE4].include?(origin)
    end
  end
end
