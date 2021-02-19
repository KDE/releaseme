# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017 Harald Sitter <sitter@kde.org>

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__)) # releaseme
$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__)) # testme
require 'testme'
require 'minitest/autorun'
