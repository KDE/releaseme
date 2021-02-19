# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2018 Harald Sitter <sitter@kde.org>

require_relative 'lib/testme'
require_relative '../lib/releaseme/tmpdir'

class TestTmpDir < Testme
  def test_prefix
    ReleaseMe.mktmpdir('X::Y??Z**A||') do |tmpdir|
      # Refute some of the windows unsafe characters.
      # Windows 10 says the following are invalid:
      #   \/:*?"<>|
      # our mktmpdir overlay specifically restricts the charactesr to known
      # safe ones rather than dropping known unsafe ones (i.e. super cautious).
      refute_includes(tmpdir, '::')
      refute_includes(tmpdir, '??')
      refute_includes(tmpdir, '**')
      refute_includes(tmpdir, '||')
    end
  end

  def test_prefix_suffix
    ReleaseMe.mktmpdir(['X::Y??Z**A||', 'X::Y??Z**A||']) do |tmpdir|
      # Refute some of the windows unsafe characters.
      # Windows 10 says the following are invalid:
      #   \/:*?"<>|
      # our mktmpdir overlay specifically restricts the charactesr to known
      # safe ones rather than dropping known unsafe ones (i.e. super cautious).
      refute_includes(tmpdir, '::')
      refute_includes(tmpdir, '??')
      refute_includes(tmpdir, '**')
      refute_includes(tmpdir, '||')
    end
  end
end
