# frozen_string_literal: true
#
# Copyright (C) 2016 Harald Sitter <sitter@kde.org>
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
