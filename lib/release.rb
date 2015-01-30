#--
# Copyright (C) 2007-2014 Harald Sitter <apachelogger@ubuntu.com>
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
#++

require_relative 'logable'
require_relative 'source'
require_relative 'xzarchive'

# FIXME: with vcs construction outside the class scope there need to be tests
#        that run a Release with all possible Vcs derivates!
# FIXME: because so much stuff happens outside this class is really incredibly
#        useless

class Release
  prepend Logable

  # The vcs from which to get the source
  attr_reader :project
  # The origin to release from
  attr_reader :origin
  # The version to release
  attr_reader :version
  # The source object from which the release is done
  attr_reader :source
  # The archive object which will create the archive
  attr_reader :archive_

  # Init
  # @param project [Project] the Project to release
  # @param origin [Symbol] the origin to release from :trunk or :stable
  # @param version [String] the versin to release as
  def initialize(project, origin, version)
    @project = project
    @source = Source.new
    @archive_ = XzArchive.new
    @origin = origin
    @version = version

    # FIXME: this possibly should be logic inside Project itself?
    project.vcs.branch = project.i18n_trunk if origin == :trunk
    project.vcs.branch = project.i18n_stable if origin == :stable

    source.target = "#{project.identifier}-#{version}"
  end

  # Get the source
  def get
    log_info "Getting source #{project.vcs}"
    source.cleanup
    source.get(project.vcs)
  end

  # FIXME: archive is an attr and a method, lovely
  # Create the final archive file
  def archive
    log_info "Archiving source #{project.vcs}"
    source.clean(project.vcs)
    @archive_.directory = source.target
    @archive_.create
  end
end
