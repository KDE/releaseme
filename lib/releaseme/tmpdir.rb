# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2018 Harald Sitter <sitter@kde.org>

require 'tmpdir'

# ReleaseMe release tool library.
module ReleaseMe
  module_function

  # Overlay for Dir.mktmpdir to ensure no invalid characters are used for
  # Windows. This is asserted on all platforms for practical reasons... invalid
  # prefixes/suffixes should not be constructed regardless of the platform.
  def mktmpdir(prefix_suffix, *args, &block)
    if prefix_suffix.is_a?(String)
      prefix_suffix = prefix_suffix.gsub(/[^0-9A-Za-z.\-_]/, '_')
    elsif prefix_suffix.is_a?(Array)
      prefix_suffix = prefix_suffix.collect do |x|
        x.gsub(/[^0-9A-Za-z.\-_]/, '_')
      end
    end
    ENV['SANITIZED_PREFIX_SUFFIX'] = '1' # Used in testme. Resets automatically.
    Dir.mktmpdir(prefix_suffix, *args, &block)
  end
end
