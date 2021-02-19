# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2016 Jonathan Riddell <jr@jriddell.org>
# SPDX-FileCopyrightText: 2016 Harald Sitter <sitter@kde.org>

require_relative '../../lib/releaseme/template'
require_relative 'plasma_version'

# Base plasma template.
class PlasmaTemplate < ReleaseMe::Template
  def initialize(template_name)
    @name = template_name
  end

  def render_binding
    PlasmaVersion.new.the_binding
  end

  def render
    super("#{__dir__}/../templates/#{@name}.md.erb")
  end
end
