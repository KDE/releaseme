# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2016 Jonathan Riddell <jr@jriddell.org>
# SPDX-FileCopyrightText: 2016 Harald Sitter <sitter@kde.org>

require_relative 'plasma_template'

# Use to create an info page for display at e.g. https://www.kde.org/info/plasma-5.6.4.php
class PlasmaInfoTemplate < PlasmaTemplate
  def initialize
    super('plasma_info_template')
  end
end
