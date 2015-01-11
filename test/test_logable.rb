#--
# Copyright (C) 2015 Harald Sitter <sitter@kde.org>
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

require_relative "lib/testme"

require_relative "../lib/logable"

class FakeClass1
  include Logable
end

class FakeClass2 < FakeClass1
  attr_accessor :log_file
  attr_accessor :log_level

  def create_logger
    logger = Logger.new(log_file)
    logger.level = log_level
    logger.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end
    return logger
  end
end

class TestLogable < Testme
  def test_privacy
    fake = FakeClass1.new
    assert_raise NoMethodError do
      fake.log_warn 'kitten'
    end
    assert_raise NoMethodError do
      fake.log_info 'kitten'
    end
    assert_raise NoMethodError do
      fake.log_debug 'kitten'
    end
  end

  def test_init
    fake = FakeClass1.new
    assert_equal(fake.instance_variables, []) # lazy init
    assert_nothing_raised do
      fake.send :log_debug, 'kitten'
    end
    assert_equal(fake.instance_variables, [:@__logger]) # lazy init
  end

  def test_format
    fake = FakeClass2.new
    fake.log_file = __callee__.to_s
    fake.log_level = Logger::WARN
    fake.send :log_warn, 'kitten'
    assert_equal("kitten\n", File.read(fake.log_file).lines.last)
  end

  def test_level
    fake = FakeClass2.new
    fake.log_file = __callee__.to_s
    fake.log_level = Logger::INFO
    fake.send :log_warn, 'warn'
    fake.send :log_info, 'info'
    fake.send :log_debug, 'debug'
    assert_equal("warn\n", File.read(fake.log_file).lines[-2])
    assert_equal("info\n", File.read(fake.log_file).lines[-1])
  end
end
