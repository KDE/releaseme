# frozen_string_literal: true
#
# Copyright (C) 2016 Harald Sitter <sitter@kde.org>
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
require_relative '../lib/releaseme/template'

class TestTemplate < Testme
  module BindingProvider
    def yolo
      self.class.to_s
    end
  end

  class BindingTemplate < ReleaseMe::Template
    include BindingProvider
  end

  class RenderBindingProvider
    include BindingProvider

    def the_binding
      binding
    end
  end

  class RenderBindingTemplate < ReleaseMe::Template
    include BindingProvider

    def render_binding
      RenderBindingProvider.new.the_binding
    end
  end

  def test_render
    # Class without #render_binding
    File.write('temp', '<%= yolo %>')
    output = BindingTemplate.new.render('temp')
    assert_equal(BindingTemplate.new.yolo, output)
  end

  def test_render_binding
    # Class without #render_binding should use render_binding instead of the
    # classes' binding. To test that the class is a BindingProvider, it also
    # has a render_binding method getting the binding from another binding
    # provider though. We expect the correct provider to get rendered.
    File.write('temp', '<%= yolo %>')
    output = RenderBindingTemplate.new.render('temp')
    assert_equal(RenderBindingProvider.new.yolo, output)
  end
end
