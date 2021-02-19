# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2016 Jonathan Riddell <jr@jriddell.org>

require 'erb'

# Open a .erb file and bind to current object,
# intended to be overloaded by an object which sets the values uesd ub the
# .erb file
module ReleaseMe
  class Template
    def render(path)
      renderer = ERB.new(File.read(path))
      renderer.result(respond_to?(:render_binding) ? render_binding : binding)
    end
  end
end
