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
require_relative '../plasma/lib/plasma_www_index_template'

class TestPlasmaRelease < Testme
  def setup
    PlasmaVersion.versions_path = data('plasma-webpages/VERSIONS.inc')
  end

  def teardown
    PlasmaVersion.versions_path = nil
  end

  def test_www_index_render
    ref = File.read(data('plasma-release/index.php'))
    refute_equal('', ref)
    template = PlasmaWWWIndexTemplate.new
    output = template.render
    assert_equal(ref, output)
  end

  def test_www_index_updater
    ref = File.read(data('plasma-release/index-full-edited.php'))
    refute_equal('', ref)

    wwwindexupdater = WWWIndexUpdater.new
    wwwindexupdater.wwwcheckout = data('plasma-release/index-full.php')
    index_html = wwwindexupdater.rewrite_index

    assert_equal(ref, index_html)
  end
end
