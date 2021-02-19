# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2015-2017 Harald Sitter <sitter@kde.org>

BEGIN {
  require_relative 'requirement_checker'
  ReleaseMe::RequirementChecker.new.check
}
