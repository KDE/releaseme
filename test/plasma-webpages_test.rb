# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2016-2020 Jonathan Riddell <jr@jriddell.org>
# SPDX-FileCopyrightText: 2016-2017 Harald Sitter <sitter@kde.org>
# SPDX-FileCopyrightText: 2018 Bhushan Shah <bhush94@gmail.com>
# SPDX-FileCopyrightText: 2020 Carl Schwan <carl@carlschwan.eu>

require 'fileutils'

require_relative 'lib/testme'
require_relative '../plasma/lib/plasma_info_template'
require_relative '../plasma/lib/plasma_announce_template'

class TestPlasmaWebpages < Testme
  def setup
    PlasmaVersion.versions_path = data('plasma-webpages/VERSIONS.inc')
  end

  def teardown
    PlasmaVersion.versions_path = nil
  end

  def test_info_render
    ref = File.read(data('plasma-webpages/info-plasma-5.9.1.md'))
    refute_equal('', ref)
    template = PlasmaInfoTemplate.new
    output = template.render
    assert_equal(ref, output)
  end

  def test_announce_render
    ref = File.read(data('plasma-webpages/announce-plasma-5.9.1.md'))
    refute_equal('', ref)
    template = PlasmaAnnounceTemplate.new
    output = template.render
    # File.open('/home/jr/tmp/OUTPUT', 'w') { |file| file.write(output) }
    # File.open('/home/jr/tmp/REF', 'w') { |file| file.write(ref) }
    assert_equal(ref.split($/), output.split($/))
  end

  def test_versions
    plasma_versions = PlasmaVersion.new
    refute_equal({}, plasma_versions.values)
    assert_equal('5.9.1', plasma_versions.values['VERSION'])
    assert_equal('5.9.1', plasma_versions.version)
    assert_equal('Bugfix', plasma_versions.values['RELEASETYPE'])
    assert_equal('Bugfix', plasma_versions.releasetype)
    assert_raises NoMethodError do
      plasma_versions.yolo
    end
  end
end
