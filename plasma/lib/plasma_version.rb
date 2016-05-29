# Copyright (C) 2016 Jonathan Riddell <jr@jriddell.org>
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

require 'ostruct'
require 'shellwords'

# Read the VERSIONS.inc file used by releaseme/plasma scripts to set various
# values which differ between Plasma releases
class PlasmaVersion
  attr_reader :values

  def initialize
    @values = {}
    versions = File.read("#{__dir__}/../VERSIONS.inc")
    versions.split($/).each do |line|
      parse_line(line)
    end
    @mapped_values = @values.map { |k, v| [k.downcase.to_sym, v] }.to_h
  end

  def the_binding
    binding
  end

  def method_missing(*args, **kwords)
    meth = args[0]
    return @mapped_values.fetch(meth) if @mapped_values.key?(meth)
    super
  end

  private

  def parse_line(line)
    line.strip!
    return if line.empty?
    return if line[0] == '#'
    line = line.split('#', 2)[0]
    key, value = line.split('=')
    value = Shellwords.split(value)
    value = value[0] if value.size == 1
    @values[key] = value
  end
end
