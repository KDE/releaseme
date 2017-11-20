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

require 'fileutils'

require_relative 'lib/testme'
require_relative '../lib/releaseme/assert_case_insensitive'

class TestAssertCaseInsensitive < Testme
  def setup
    @dir = 'sourcy'
    teardown # Make sure everything is clean...
    Dir.mkdir(@dir)
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_case_sensitive
    a = "#{@dir}/foo.txt"
    b = "#{@dir}/Foo.txt"

    File.write(a, 'a')
    File.write(b, 'b')

    # Only works on case sensitive file systems obviously
    unless File.read(a) == 'a' && File.read(b) == 'b'
      return # Which the current one is not!
    end

    File.write("#{@dir}/bar.txt", '')

    assert_raises ReleaseMe::AssertionFailedError do
      ReleaseMe::AssertCaseInsensitive.assert(@dir)
    end
  end

  def test_case_insensitive
    # i.e. no conflict; passes assertion

    FileUtils.mkpath("#{@dir}/subdir1")
    FileUtils.mkpath("#{@dir}/subdir2")
    File.write("#{@dir}/foo.txt", 'a')
    File.write("#{@dir}/bar.txt", 'b')
    File.write("#{@dir}/subdir1/foo.txt", 'c')
    File.write("#{@dir}/subdir2/foo.txt", 'd')

    ReleaseMe::AssertCaseInsensitive.assert(@dir)
  end
end
