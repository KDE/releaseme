#--
# Copyright (C) 2007-2015 Harald Sitter <sitter@kde.org>
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

class Vcs
  # The repository URL
  attr_accessor :repository

  # Does a standard get operation. Obtaining repository.url into target.
  def get(target)
    raise "Pure virtual"
  end

  # Does a standard clean operation. Removing any VCS data from target (e.g. .git/.svn etc.)
  def clean!(target)
    raise "Pure virtual"
  end

  # Construct a VCS instance from a hash defining its attributes.
  # FIXME: why is this not simply an init? Oo
  def self.from_hash(hash)
    vcs = self.new
    hash.each do |key, value|
      vcs.send("#{key}=".to_sym, value)
    end
    return vcs
  end
end
