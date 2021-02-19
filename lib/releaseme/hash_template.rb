# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017 Harald Sitter <sitter@kde.org>

require_relative 'template'

module ReleaseMe
  # Simple Template providing a binding context around a hash. The hash
  # keys are exposed as methods in the binding context.
  # The hash keys must be symbols.
  class HashTemplate < Template
    def initialize(hash)
      @hash = hash
    end

    def method_missing(meth, *args)
      @hash.fetch(meth) { super }
    end

    def respond_to_missing?(meth, *)
      @hash.include?(meth) || super
    end
  end
end
