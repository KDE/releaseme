#--
# Copyright (C) 2007-2015 Harald Sitter <apachelogger@ubuntu.com>
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

require_relative 'archive_signer'
require_relative 'documentation'
require_relative 'l10n'
require_relative 'logable'
require_relative 'source'
require_relative 'xzarchive'

# FIXME: with vcs construction outside the class scope there need to be tests
#        that run a Release with all possible Vcs derivates!
# FIXME: because so much stuff happens outside this class is really incredibly
#        useless

module ReleaseMe
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
      if project.vcs.is_a? Git
        project.vcs.branch = case origin
                             when :trunk
                               project.i18n_trunk
                             when :stable
                               project.i18n_stable
                             when :lts
                               project.i18n_lts
                             else
                               raise "Origin #{origin} unsupported. See readme."
                             end
      end

      source.target = "#{project.identifier}-#{version}"
    end

    # Get the source
    # FIXME: l10n and documentation have no test backing
    def get
      log_info "Getting CI states."
      check_ci!

      log_info "Getting source #{project.vcs}"
      play if ENV.key?('RELEASE_THE_BEAT')
      source.cleanup
      source.get(project.vcs)

      # FIXME: one would think that perhaps l10n could be disabled entirely
      log_info ' Getting translations...'
      # FIXME: why not pass project itself? Oo
      # FIXME: origin should be validated? technically optparse enforces proper values
      l10n = L10n.new(origin, project.identifier, project.i18n_path)
      l10n.get(source.target)

      log_info ' Getting documentation...'
      doc = DocumentationL10n.new(origin, project.identifier, project.i18n_path)
      doc.get(source.target)
    end

    # FIXME: archive is an attr and a method, lovely
    # Create the final archive file
    def archive
      log_info "Archiving source #{project.vcs}"
      source.clean(project.vcs)
      @archive_.directory = source.target
      @archive_.create
      ArchiveSigner.new.sign(@archive_)
    end

    private

    def check_ci!
      jobs = Jenkins::Job.from_name_and_branch(project.identifier,
                                               project.vcs.branch)
      jobs.select! do |job|
        next false if job.sufficient_quality?
        log_warn <<-EOF
build.kde.org: #{job.display_name} is not of sufficient quality #{job.url}"
EOF
        true
      end
      continue?(jobs)
    end

    def continue?(jobs)
      return if jobs.empty?
      loop do
        puts 'Continue despite shitty jobs? [y/n]'
        case gets.strip
        when 'y'
          break
        when 'n'
          abort
        end
      end
    end

    def play
      url = case ENV.fetch('RELEASE_THE_BEAT', '')
            when 'jam'
              'https://www.youtube.com/watch?v=EpkYIy6UhI4'
            else
              'https://www.youtube.com/watch?v=fNNdOFwQjcU'
            end
      return unless url
      play_thread(url)
    end

    def play_thread(url)
      Thread.new do
        loop do
          ret = system(*(%w(vlc --no-video --play-and-exit --intf dummy) << url),
                       pgroup: Process.pid)
          break unless ret
        end
      end
    end
  end
end
