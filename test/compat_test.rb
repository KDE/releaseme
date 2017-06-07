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
