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

basename = File.basename(__FILE__)
warn <<-EOF
Warning: requiring old file #{basename}, should require releaseme/#{basename}
  instead @ #{caller[0]}
EOF
require_relative "releaseme/#{basename}"

# Compatibility map all consts out of the gem module into the root Object
# scope.
ReleaseMe.constants.each do |class_name|
  next if class_name == 'ReleaseMe' # Do not map gem module itself.
  next if Object.const_defined?(class_name)
  # Should this restriction become a problem we'll need to establish a whitelist
  # of entities we want to compat map. i.e. old classes. Fully mapping
  # nested modules/classes is neither called for nor useful.
  klass = ReleaseMe.const_get(class_name)
  warn "Compat mapping ReleaseMe::#{class_name} ➜ #{class_name}"
  Object.const_set(class_name, klass)
end
