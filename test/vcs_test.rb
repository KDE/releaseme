# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2015 Harald Sitter <sitter@kde.org>

require_relative 'lib/testme'
require_relative '../lib/releaseme/git'

class TestVcs < Testme
  def test_default
    assert_nil(ReleaseMe::Git.new.repository)
  end

  def test_from_hash
    vcs = ReleaseMe::Git.from_hash({"repository" => "kitten"})
    refute_nil(vcs)
    assert_equal("kitten", vcs.repository)
  end
end
