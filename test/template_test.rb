# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2016 Harald Sitter <sitter@kde.org>

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
