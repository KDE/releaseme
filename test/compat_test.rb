# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017 Harald Sitter <sitter@kde.org>

require_relative 'lib/testme'

class TestCompat < Testme
  def test_compat_compat
    # Requiring a compat file needs to expose the contained class in the
    # root scope. Additionally the gem module scope should have it available,
    # and the thing should be able to
    refute_includes(Object.constants, :ReleaseMeCompatCompat)
    require_relative '../lib/compat_compat'
    assert_includes(Object.constants, :ReleaseMeCompatCompat)
    assert_includes(Object.constants, :ReleaseMe)
    assert_includes(ReleaseMe.constants, :ReleaseMeCompatCompat)
    refute_nil(ReleaseMeCompatCompat.new) # able to init
  end

  # Make sure tests load the new files rather than the old ones.
  lib_dir = "#{File.dirname(__dir__)}/lib"
  gem_dir = "#{lib_dir}/releaseme"
  Dir.glob("#{__dir__}/*.rb").each do |file|
    basename = File.basename(file)
    next if basename == File.basename(__FILE__)
    next if basename.include?('test_compat.rb') # we are allowed to!
    next if basename.include?('test_releaseme.rb') # so releaseme!
    sanename = basename.delete(' ').delete('/').delete('.')
    define_method("test_#{sanename}".to_sym) do
      # Hop into dir as otherwise we won't be able to expand_path properly.
      Dir.chdir(__dir__)
      File.read(file).each_line do |line|
        data = line.match(/^\s*require_relative\s+["|']([^\s]+)["|'].*$/)
        next unless data
        require_data = data[1]
        required_file = File.expand_path(require_data)
        next unless required_file.start_with?(lib_dir)
        assert(required_file.start_with?(gem_dir), <<-EOF)
The tests/#{File.basename(file)} requires #{require_data} which appears to be a
library that is in the legacy lib dir rather than the new gem dir. Tests
must require the new files rather than the old ones.
Require should be '../lib/releaseme/' rather than '../lib/'.
EOF
      end
    end
  end
end
