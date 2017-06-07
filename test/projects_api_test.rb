#--
# Copyright (C) 2017 Harald Sitter <sitter@kde.org>
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

require_relative 'lib/testme'
require_relative '../lib/releaseme/projects_api'

class TestProjectsAPISnake < Testme
  def test_snake_a_sym_hash
    snake = ReleaseMe::ProjectsAPI::Snake.it(fooBar: 'fish')
    assert_equal({ foo_bar: 'fish' }, snake)
  end

  def test_snake_a_string_hash
    snake = ReleaseMe::ProjectsAPI::Snake.it('fooBar' => 'fish')
    assert_equal({ 'foo_bar' => 'fish' }, snake)
  end

  def test_snake_a_weird_hash
    snake = ReleaseMe::ProjectsAPI::Snake.it(1 => 'fish')
    assert_equal({ 1 => 'fish' }, snake)
  end
end
