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

require "fileutils"
require 'rexml/document'

require_relative "lib/testme"

require_relative "../lib/projectsfile"

class TestProjectFile < Testme
  def setup
    # Project uses ProjectsFile to read data, so we need to make sure it
    # uses our dummy file.
    ProjectsFile.reset!
    ProjectsFile.xml_path = data('kde_projects_advanced.xml')
  end

  def teardown
    ProjectsFile.reset!
  end

  def test_set_xml
    # set in setup
    assert_equal(ProjectsFile.xml_path, data('kde_projects_advanced.xml'))
  end

  def test_reset
    ProjectsFile.autoload = true
    assert_equal(ProjectsFile.xml_path, data('kde_projects_advanced.xml'))
    assert_not_nil(ProjectsFile.xml_data)
    assert_not_nil(ProjectsFile.xml_doc)
    ProjectsFile.reset!
    ProjectsFile.autoload = false
    assert_nil(ProjectsFile.xml_doc)
    assert_nil(ProjectsFile.xml_data)
    assert_not_equal(ProjectsFile.xml_path, data('kde_projects_advanced.xml'))
  end

  def test_load
    ProjectsFile.load!
    assert_not_nil(ProjectsFile.xml_data)
    assert_not_nil(ProjectsFile.xml_doc)
  end

  def test_parse
    data = File.read(ProjectsFile.xml_path)
    assert_equal(ProjectsFile.xml_data, data)
    # REXML has no dep compare capability, so we'll settle for size compare.
    assert_equal(ProjectsFile.xml_doc.size, REXML::Document.new(data).size)
  end
end
