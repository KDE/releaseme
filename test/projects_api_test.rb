# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017 Harald Sitter <sitter@kde.org>

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
