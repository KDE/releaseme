# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2024 Jonathan Riddell <jr@jriddell.org>

require_relative 'plasma_template'

class FrameworksAnnounceTemplate < PlasmaTemplate
  def initialize
    super('frameworks_announce_template')
  end
end
