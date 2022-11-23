#!/usr/bin/env ruby
# frozen_string_literal: true

# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2022 Harald Sitter <sitter@kde.org>

require 'drb/drb'

DRb.start_service

server = DRbObject.new_with_uri("drbunix:#{Dir.home}/drb.socket")
server.release(appstream_id: 'org.kde.filelight', factory_job: 'Filelight_Release_win64')
