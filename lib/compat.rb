#--
# Copyright (C) 2017 Harald Sitter <sitter@kde.org>
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
#++

# :nocov:
# realpath so we get compat.rb not a symlink, vs. absolute_path so we get when
# symlink if applicable
if File.realpath(__FILE__) == File.absolute_path($PROGRAM_NAME)
  # Update compat links when running compat directly.
  Dir.chdir(__dir__)
  files = Dir.chdir('releaseme') { Dir.glob('*') }
  files.each do |file|
    puts "Symlinking #{__FILE__} ➜ #{file}"
    File.delete(file) if File.symlink?(file) || File.exist?(file)
    File.symlink(File.basename(__FILE__), file)
  end
  exit
end
# :nocov:

# Fancy event listener. We'll get notified of all class definitions in the file
# we require and set compat class names without module.
# NOTE: This still means that X.new will be class ReleaseMe::X rather than
#   simply X.
# rubocop:disable Metrics/ParameterLists
set_trace_func proc { |event, file, _line, _id, binding, _classname|
  # rubocop:enable
  unless File.absolute_path(file) ==
         File.absolute_path("#{__dir__}/releaseme/#{File.basename(__FILE__)}")
    next
  end
  next if event != 'class'
  class_name = eval('name', binding)
  klass = Object.const_get(class_name)
  next unless klass.is_a?(Class) # Do not forward modules.
  next unless class_name.include?('::') # No need forwarding toplevel classes.
  # Should this restriction become a problem we'll need to establish a whitelist
  # of entities we want to compat map. i.e. old classes. Fully mapping
  # nested modules/classes is neither called for nor useful.
  raise if class_name.count(':') > 2
  class_name_base = class_name.split('::')[-1]
  Object.const_set(class_name_base.to_sym, klass)
}

basename = File.basename(__FILE__)
warn <<-EOF
Warning: requiring old file #{basename}, should require releaseme/#{basename}
  instead @ #{caller[0]}
EOF
require_relative "releaseme/#{basename}"
set_trace_func(nil) # unset listener again
