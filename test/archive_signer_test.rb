# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2016 Harald Sitter <sitter@kde.org>

require 'fileutils'

require_relative 'test_helper'
require_relative 'lib/testme'
require_relative '../lib/releaseme/archive_signer'
require_relative '../lib/releaseme/xzarchive'

class TestArchiveSigner < Testme
  def test_sign
    Dir.mkdir('wroom')
    archive = ReleaseMe::XzArchive.new
    archive.directory = 'wroom'
    archive.create
    assert_path_exist(archive.filename)
    Dir.delete('wroom')
    system("tar -xf #{archive.filename}")
    assert_path_exist('wroom')

    signer = ReleaseMe::ArchiveSigner.new
    signer.sign(archive)
    assert_path_exist(signer.signature)
    assert(system("gpg2 --verify #{signer.signature}",
                  %i[out err] => File::NULL))
  end
end
