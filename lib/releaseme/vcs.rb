# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2007-2015 Harald Sitter <sitter@kde.org>

module ReleaseMe
  # Version control system base class.
  # Doesn't do anything on its own.
  class Vcs
    # The repository URL
    attr_accessor :repository

    # Does a standard get operation. Obtaining repository.url into target.
    def get(_target)
      raise 'Pure virtual'
    end

    # Does a standard clean operation. Removing any VCS data from target
    # (e.g. .git/.svn etc.)
    def clean!(_target)
      raise 'Pure virtual'
    end

    # Construct a VCS instance from a hash defining its attributes.
    # FIXME: why is this not simply an init? Oo
    def self.from_hash(hash)
      vcs = new
      hash.each do |key, value|
        vcs.send("#{key}=".to_sym, value)
      end
      vcs
    end
  end
end
