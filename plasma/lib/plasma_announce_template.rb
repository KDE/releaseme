# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2016 Jonathan Riddell <jr@jriddell.org>
# SPDX-FileCopyrightText: 2016 Harald Sitter <sitter@kde.org>

require_relative 'plasma_template'

class PlasmaAnnounceTemplate < PlasmaTemplate
  def initialize
    super('plasma_announce_template')
  end
end
