# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2015-2017 Harald Sitter <sitter@kde.org>

# Implements a shutup method to check if output should be done or not
module ReleaseMe
  # Helper methods to determine whether to be silent or not (i.e. should
  # output be generated or not)
  module Silencer
    # Methods extending the Object a {Logable} is included in. All methods are
    # private by default.
    module Methods
      # @!visibility public

      def shutup?
        ENV['RELEASEME_SHUTUP'] && !ENV['RELEASEME_DEBUG']
      end
    end

    extend Methods
    # @!parse extend Methods

    # @!visibility private
    def self.prepended(base)
      base.extend(Methods)
      base.prepend(Methods)
    end

    # @!visibility private
    def self.included(base)
      base.extend(Methods)
      base.include(Methods)
    end
  end
end
