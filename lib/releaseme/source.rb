# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2007-2014 Harald Sitter <sitter@kde.org>

require 'fileutils'

module ReleaseMe
  class Source
    # The target directory
    attr_accessor :target

    # Cleans the source for archiving (e.g. removes .git directory).
    def clean(vcs)
      vcs.clean!(target)
    end

    # Cleans up data created
    def cleanup
      FileUtils.rm_rf(target)
    end

    # Gets the source
    def get(vcs, shallow = true)
      # FIXME: this is a bloody warkaround for the fact that vcs itself
      #        doesn't actually know about shallows, but git does and
      #        for tarme shallow is desirable whereas for tagme we need a full
      #        clone....
      #        perhaps a bool:shallow attribute on the vcs would help?
      vcs.get(target, shallow)
    rescue
      vcs.get(target)
    end

  end
end
