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

require_relative 'silencer'

module ReleaseMe
  # Signs an archive (i.e. tarball)
  class ArchiveSigner
    attr_reader :signature

    def initialize
      @signature = nil
    end

    def sign(archive)
      file = archive.filename
      sigfile = "#{file}.sig"
      args = Silencer.shutup? ? { %i[out err] => '/dev/null' } : {}
      system("gpg2 --armor --detach-sign -o #{sigfile} #{file}", args) || raise
      @signature = File.absolute_path(sigfile)
    end
  end
end
