# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2018 Jonathan Riddell <jr@jriddell.org>

require_relative 'plasma_template'

# Generate new Plasma text block for www.kde.org/index.php
class PlasmaWWWIndexTemplate < PlasmaTemplate
  def initialize
    super('plasma_www_index_template')
  end
end

# Insert the new block into the php file
class WWWIndexUpdater
  attr_accessor :wwwcheckout

  def initialize
    @plasma_versions = PlasmaVersion.new
    @wwwcheckout = @plasma_versions.wwwcheckout + "/index.php"
  end

  def rewrite_index
    index_template = PlasmaWWWIndexTemplate.new
    new_announce_block_output = index_template.render

    index_html = nil
    open(@wwwcheckout) do |f|
        index_html = f.readlines()
    end

    # take out old text
    old_announce_block_index = index_html.index do |line|
      line.include?('Today KDE releases a new')
    end

    (0..5).each do
      index_html.delete_at(old_announce_block_index - 3)
    end

    # add in new text
    marker_line = index_html.index("                <!-- This comment is a marker for Latest Announcements, used by scripts -->\n")
    index_html.insert(marker_line+1, new_announce_block_output)

    # convert to string
    output = ''
    index_html.each do |line|
      output += line
    end
    output
  end
end
