# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2016 Jonathan Riddell <jr@jriddell.org>

require 'shellwords'

# Read the VERSIONS.inc file used by releaseme/plasma scripts to set various
# values which differ between Plasma releases
class PlasmaVersion
  attr_reader :values

  def self.versions_path
    @versions_path ||= "#{__dir__}/../VERSIONS.inc"
  end

  def self.versions_path=(value)
    @versions_path = value
  end

  def initialize
    @values = {}
    versions = File.read(self.class.versions_path)
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
