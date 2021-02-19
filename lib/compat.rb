# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017 Harald Sitter <sitter@kde.org>

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
  next if Object.const_defined?(class_name)
  next if class_name == 'ReleaseMe' # Do not map gem module itself.
  # Should this restriction become a problem we'll need to establish a whitelist
  # of entities we want to compat map. i.e. old classes. Fully mapping
  # nested modules/classes is neither called for nor useful.
  klass = ReleaseMe.const_get(class_name)
  if ENV['RELEASEME_DEBUG']
    warn "Compat mapping ReleaseMe::#{class_name} ➜ #{class_name}"
  end
  Object.const_set(class_name, klass)
end
