#--
# Copyright (C) 2015 Harald Sitter <apachelogger@ubuntu.com>
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
require 'rexml/document'
require 'webmock/test_unit'

require_relative 'lib/testme'

require_relative '../lib/releaseme/projectsfile'

class TestProjectFile < Testme
  def setup_caching
    # Moving caching into tmp scope
    @cache_dir = "#{Dir.pwd}/.cache/releaseme"
    ReleaseMe::ProjectsFile.instance_variable_set(:@cache_dir, @cache_dir)
    FileUtils.mkpath(@cache_dir)

    @cache_file = ReleaseMe::ProjectsFile.send(:cache_file)
    @cache_file_date = ReleaseMe::ProjectsFile.send(:cache_file_date)
  end

  def setup
    WebMock.disable_net_connect!
    # Project uses ProjectsFile to read data, so we need to make sure it
    # uses our dummy file.
    ReleaseMe::ProjectsFile.reset!
    ReleaseMe::ProjectsFile.xml_path = data('kde_projects_advanced.xml')

    setup_caching
  end

  def teardown
    ReleaseMe::ProjectsFile.reset!
    WebMock.allow_net_connect!
  end

  def test_set_xml
    # set in setup
    assert_equal(ReleaseMe::ProjectsFile.xml_path, data('kde_projects_advanced.xml'))
  end

  def test_reset
    ReleaseMe::ProjectsFile.autoload = true
    assert_equal(ReleaseMe::ProjectsFile.xml_path, data('kde_projects_advanced.xml'))
    assert_not_nil(ReleaseMe::ProjectsFile.xml_data)
    assert_not_nil(ReleaseMe::ProjectsFile.xml_doc)
    ReleaseMe::ProjectsFile.reset!
    ReleaseMe::ProjectsFile.autoload = false
    assert_nil(ReleaseMe::ProjectsFile.xml_doc)
    assert_nil(ReleaseMe::ProjectsFile.xml_data)
    assert_not_equal(ReleaseMe::ProjectsFile.xml_path, data('kde_projects_advanced.xml'))
  end

  def test_load
    ReleaseMe::ProjectsFile.load!
    assert_not_nil(ReleaseMe::ProjectsFile.xml_data)
    assert_not_nil(ReleaseMe::ProjectsFile.xml_doc)
  end

  def test_load_http
    # Revert the xml twiddling from setup and only divert the cache.
    # We need the canonical xml url for this test.
    file = ReleaseMe::ProjectsFile.xml_path
    ReleaseMe::ProjectsFile.reset!
    setup_caching

    date = 'Thu, 16 Jun 2016 10:55:16 GMT'

    assert(!File.exist?(@cache_file))
    assert(!File.exist?(@cache_file_date))

    # Request against stub, we are expecting our cache files as a result.
    # We EXPECT https://! anything else means the request is malformed.
    # This also includes http requests against 443
    stub = stub_request(:any, 'https://projects.kde.org/kde_projects.xml')
    stub.to_return do |_|
      {
        body: File.read(file),
        headers: { 'date' => date }
      }
    end
    ReleaseMe::ProjectsFile.load!
    assert_not_nil(ReleaseMe::ProjectsFile.xml_data)
    assert_not_nil(ReleaseMe::ProjectsFile.xml_doc)
    assert_path_exist(@cache_file, 'cache file missing')
    assert_path_exist(@cache_file_date, 'date cache missing')
    remove_request_stub(stub)

    # Now that we have a cache, try to use the cache.
    prev_mtime = File.mtime(@cache_file)
    stub = stub_request(:any, 'https://projects.kde.org/kde_projects.xml')
    stub.with(headers: { 'If-Modified-Since' => date })
    stub.to_return(status: [304, 'Not Modified'])
    ReleaseMe::ProjectsFile.load!
    assert_not_nil(ReleaseMe::ProjectsFile.xml_data)
    assert_not_nil(ReleaseMe::ProjectsFile.xml_doc)
    assert_path_exist(@cache_file, 'cache file missing')
    assert_path_exist(@cache_file_date, 'date cache missing')
    remove_request_stub(stub)
    assert_equal(prev_mtime, File.mtime(@cache_file),
                 'Cache file was modified but should not have been.')

    # And again, but this time we want the cache to update.
    prev_mtime = File.mtime(@cache_file)
    stub = stub_request(:any, 'https://projects.kde.org/kde_projects.xml')
    stub.with(headers: { 'If-Modified-Since' => date })
    stub.to_return(body: File.read(file), headers: { 'date' => date })
    ReleaseMe::ProjectsFile.load!
    assert_not_nil(ReleaseMe::ProjectsFile.xml_data)
    assert_not_nil(ReleaseMe::ProjectsFile.xml_doc)
    assert_path_exist(@cache_file, 'cache file missing')
    assert_path_exist(@cache_file_date, 'date cache missing')
    remove_request_stub(stub)
    assert_not_equal(prev_mtime, File.mtime(@cache_file),
                     'Cache file should have been modified but was not.')

    # Last time, we'll let this one fall into cache.
    prev_mtime = File.mtime(@cache_file)
    stub = stub_request(:any, 'https://projects.kde.org/kde_projects.xml')
    stub.to_return(status: 500)
    ReleaseMe::ProjectsFile.load!
    assert_not_nil(ReleaseMe::ProjectsFile.xml_data)
    assert_not_nil(ReleaseMe::ProjectsFile.xml_doc)
    assert_path_exist(@cache_file, 'cache file missing')
    assert_path_exist(@cache_file_date, 'date cache missing')
    remove_request_stub(stub)
    assert_equal(prev_mtime, File.mtime(@cache_file),
                 'Cache file should not have been modified but was.')
  end

  def test_parse
    data = File.read(ReleaseMe::ProjectsFile.xml_path)
    assert_equal(ReleaseMe::ProjectsFile.xml_data, data)
    # REXML has no dep compare capability, so we'll settle for size compare.
    assert_equal(ReleaseMe::ProjectsFile.xml_doc.size, REXML::Document.new(data).size)
  end
end
