# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2016 Harald Sitter <sitter@kde.org>

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
      args = Silencer.shutup? ? { %i[out err] => File::NULL } : {}
      system("gpg2 --armor --detach-sign -o #{sigfile} #{file}", args) || raise
      @signature = File.absolute_path(sigfile)
    end
  end
end
