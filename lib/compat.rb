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
