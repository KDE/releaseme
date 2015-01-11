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

require_relative "../lib/vcs"

class TestVcs < Testme
  def test_default
    assert_nil(Vcs.new.repository)
  end

  def test_asserts
    instance = Vcs.new
    instance_methods = Vcs.public_instance_methods(false)
    instance_methods.delete(:repository=)
    instance_methods.delete(:repository)
    instance_methods.each do |meth|
      assert_raise RuntimeError do
        argc = 0
        begin
          argv = []
          argc.times { argv << 1 }
          instance.public_send meth, argv
        rescue ArgumentError => e
          raise e if (argc >= 10)
          argc += 1
          retry
        end
      end
    end
  end

  def test_from_hash
    vcs = Vcs.from_hash({"repository" => "kitten"})
    assert_not_nil(vcs)
    assert_equal("kitten", vcs.repository)
  end
end
