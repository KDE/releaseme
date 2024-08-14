# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017 Harald Sitter <sitter@kde.org>

module ReleaseMe
  module Origin
    # The symbolic values should not ever be changed as they may be hardcoded or
    # converted to/from strings representation with outside sources.
    TRUNK = :trunk # technicall _kf5
    STABLE = :stable
    LTS = :lts
    TRUNK_KDE4 = :trunk_kde4
    STABLE_KDE4 = :stable_kde4

    ALL = [TRUNK, STABLE, LTS, TRUNK_KDE4, STABLE_KDE4].freeze

    module_function

    def kde4?(origin)
      [TRUNK_KDE4, STABLE_KDE4].include?(origin)
    end

    # The sub directory where releases are located
    def target_sub_path(origin)
      origin_target_map = { lts: "stable", stable: "stable", trunk: "unstable", stable_kde4: "stable", trunk_kde4: "unstable" }
      origin_target_map[origin]
    end
  end
end
