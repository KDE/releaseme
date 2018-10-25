# Copyright (C) 2018 Harald Sitter <sitter@kde.org>
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

require_relative 'lib/testme'
require_relative '../lib/releaseme/tmpdir'

class TestTmpDir < Testme
  def test_prefix
    Dir.mktmpdir('X::Y??Z**A||') do |tmpdir|
      # Refute some of the windows unsafe characters.
      # Windows 10 says the following are invalid:
      #   \/:*?"<>|
      # our mktmpdir overlay specifically restricts the charactesr to known
      # safe ones rather than dropping known unsafe ones (i.e. super cautious).
      refute_includes(tmpdir, '::')
      refute_includes(tmpdir, '??')
      refute_includes(tmpdir, '**')
      refute_includes(tmpdir, '||')
    end
  end

  def test_prefix_suffix
    Dir.mktmpdir(['X::Y??Z**A||', 'X::Y??Z**A||']) do |tmpdir|
      # Refute some of the windows unsafe characters.
      # Windows 10 says the following are invalid:
      #   \/:*?"<>|
      # our mktmpdir overlay specifically restricts the charactesr to known
      # safe ones rather than dropping known unsafe ones (i.e. super cautious).
      refute_includes(tmpdir, '::')
      refute_includes(tmpdir, '??')
      refute_includes(tmpdir, '**')
      refute_includes(tmpdir, '||')
    end
  end
end
