# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2015 Harald Sitter <sitter@kde.org>

require_relative 'lib/testme'
require_relative '../lib/releaseme/vcs'

class TestVcs < Testme
  def test_default
    assert_nil(ReleaseMe::Vcs.new.repository)
  end

  def test_asserts
    instance = ReleaseMe::Vcs.new
    instance_methods = ReleaseMe::Vcs.public_instance_methods(false)
    instance_methods.delete(:repository=)
    instance_methods.delete(:repository)
    instance_methods.each do |meth|
      assert_raises RuntimeError do
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
    vcs = ReleaseMe::Vcs.from_hash({"repository" => "kitten"})
    refute_nil(vcs)
    assert_equal("kitten", vcs.repository)
  end
end
