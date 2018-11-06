#!/usr/bin/env ruby

require 'test/unit'
require_relative '../plasma/lib/plasma-tag-test'

class PlasmaTagTestTest < Test::Unit::TestCase
  def setup
    @tagTest = PlasmaTagTest.new
  end

  # def teardown
  # end

  #def test_version
  #  assert_equal '5.13.90', @tagTest.version, 'Version not set.'
  #end

  def test_git_repos
    Dir.chdir("../plasma/") do
      @tagTest.grab_git_repos
      assert_equal ['bluedevil', 'breeze', 'breeze-grub'], @tagTest.repos[0..2]
      assert_equal 'xdg-desktop-portal-kde', @tagTest.repos[-1]
      assert_equal 5, @tagTest.repos.find_index('discover')
      assert_equal nil, @tagTest.repos.find_index('plasma-discover')
    end
  end
end
