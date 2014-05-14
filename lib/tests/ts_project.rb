#--
# Copyright (C) 2014 Harald Sitter <apachelogger@ubuntu.com>
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

require "fileutils"
require "test/unit"

require_relative "../project"

class TestProject < Test::Unit::TestCase

    attr :pr, false

    def setup
        @pr = Project.new()
        @pr.xml_path = Dir.pwd + '/data/kde_projects.xml'
    end

    def teardown
    end

    def test_resolve_valid
        pr.id = 'yakuake'
        ret = pr.resolve!
        assert_equal(ret, true)
        assert_equal(pr.id, 'yakuake')
        assert_equal(pr.identifier, 'yakuake')
        assert_equal(pr.module, 'utils')
        assert_equal(pr.component, 'extragear')
        assert_equal(pr.i18n_trunk, 'master')
        assert_equal(pr.i18n_stable, 'notmaster')
    end

    def test_resolve_invalid
        pr.id = 'kitten'
        ret = pr.resolve!
        assert_equal(ret, false)
        assert_equal(pr.id, 'kitten')
        assert_equal(pr.identifier, nil)
        assert_equal(pr.module, nil)
        assert_equal(pr.component, nil)
        assert_equal(pr.i18n_trunk, nil)
        assert_equal(pr.i18n_stable, nil)
    end

    def test_vcs
        pr.id = 'yakuake'
        pr.resolve!
        vcs = pr.vcs
        assert_equal(vcs.repository, 'git://anongit.kde.org/yakuake')
        assert_equal(vcs.branch, nil) # project on its own should not set a branch
    end
end
