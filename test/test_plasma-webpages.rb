# Copyright (C) 2016 Jonathan Riddell <jr@jriddell.org>
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

require 'fileutils'

require_relative 'lib/testme'
require_relative '../plasma/lib/plasma_info_template'

class TestPlasmaWebpages < Testme
  def setup
  end

  def test_render
    ref = File.read(data('plasma-webpages/plasma-5.6.4.php'))
    assert_not_equal('', ref)
    template = PlasmaInfoTemplate.new
    output = template.render
    assert_equal(ref, output)
  end

  def test_versions
    plasma_versions = PlasmaVersion.new
    assert_not_equal({}, plasma_versions.values)
    assert_equal('5.6.4', plasma_versions.values['VERSION'])
    assert_equal('bugfix', plasma_versions.values['RELEASETYPE'])
  end

end