# Copyright (C) 2018 Harald Sitter
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License or (at your option) version 3 or any later version
# accepted by the membership of KDE e.V. (or its successor approved
# by the membership of KDE e.V.), which shall act as a proxy
# defined in Section 14 of version 3 of the license.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
