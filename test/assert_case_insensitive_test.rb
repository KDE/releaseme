# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017 Harald Sitter <sitter@kde.org>

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
