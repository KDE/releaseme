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

# Implements a shutup method to check if output should be done or not
module ReleaseMe
  module Silencer
    # Methods extending the Object a {Logable} is included in. All methods are
    # private by default.
    module Methods
      # @!visibility public

      def shutup?
        ENV['RELEASEME_SHUTUP'] && !ENV['RELEASEME_DEBUG']
      end
    end

    extend Methods
    # @!parse extend Methods

    # @!visibility private
    def self.prepended(base)
      base.extend(Methods)
      base.prepend(Methods)
    end

    # @!visibility private
    def self.included(base)
      base.extend(Methods)
      base.include(Methods)
    end
  end
end
