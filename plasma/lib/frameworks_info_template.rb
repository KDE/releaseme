# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2024 Jonathan Riddell <jr@jriddell.org>

require_relative 'plasma_template'

# Use to create an info page for display at e.g. https://kde.org/info/kde-frameworks-5.245.0/
class FrameworksInfoTemplate < PlasmaTemplate
  def initialize
    super('frameworks_info_template')
  end
end
