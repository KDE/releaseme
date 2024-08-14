# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2007-2022 Harald Sitter <sitter@kde.org>

require_relative 'archive_signer'
require_relative 'gitlab'
require_relative 'hash_template'
require_relative 'logable'
require_relative 'source'
require_relative 'template'
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

      source.target = artifact_name
    end

    # Get the source
    def get
      log_info 'Getting CI states.'
      check_ci!

      log_info "Getting source #{project.vcs}"
      play if ENV.key?('RELEASE_THE_BEAT')
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
      @signature = ArchiveSigner.new.sign(@archive_)
    end

    def help
      return if Silencer.shutup?
      tar = archive_.filename
      sig = File.basename(@signature)

      uri = sysadmin_ticket(tar, sig)

      template = HashTemplate.new(tarball: tar, signature: sig, ticket_uri: uri)
      puts template.render("#{__dir__}/data/release_help.txt.erb")
    end

    private

    def artifact_name
      # WARNING: DO NOT ADD ANY NEW MAPPINGS HERE!
      # Certainly not without review by sitter. This mapping table is exclusively here for legacy stuff.
      # We've pretty much agreed that the repo name should always be the tarball name to keep everyone sane and the
      # tech simple: https://markmail.org/message/jr4za6d7c2n7bw73
      base = case project.identifier
             when 'phonon-vlc'
               'phonon-backend-vlc'
             when 'phonon-gstreamer'
               'phonon-backend-gstreamer'
             else
               project.identifier
             end
      "#{base}-#{version}"
    end

    def sysadmin_ticket(tar, sig)
      title = "Publish #{tar}"
      sha256s = [sig, tar].collect { |x| `sha256sum #{x}`.strip }
      sha1s = [sig, tar].collect { |x| `sha1sum #{x}`.strip }
      template = HashTemplate.new(sha256s: sha256s, sha1s: sha1s, version: version, projectName: project.identifier, target: ReleaseMe::Origin::target_sub_path(origin))
      template_file = "#{__dir__}/data/ticket_description.txt.erb"
      description = template.render(template_file)
      sysadmin_ticket_uri(title: title, description: description)
    end

    def sysadmin_ticket_uri(**form_data)
      uri = URI.parse('https://phabricator.kde.org/maniphest/task/edit/form/2')
      uri.query = URI.encode_www_form(**form_data)
      uri
    end

    def warn_job_state(pipeline)
      log_warn format(
        if %w[failed canceled skipped].none? { |x| x == pipeline['status'] }
          'invent.kde.org: pipeline %s is still building [%s]'
        else
          'invent.kde.org: pipeline %s is not of sufficient quality [%s]'
        end, pipeline['id'], pipeline['status']
      )
    end

    def check_ci!
      GitLab::Pipeline.each_from_repository_and_branch(project.vcs.repository, project.vcs.branch) do |pipeline|
        auto_continue = pipeline['status'] == 'success'
        break if auto_continue

        warn_job_state(pipeline)
        continue?
        break
      end
    end

    def continue?
      loop do
        ARGV.clear
        puts 'Continue despite unexpected pipeline states? [y/n]' unless shutup?
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
          ret = system(*(%w[vlc --no-video --play-and-exit --intf dummy] << url),
                       pgroup: Process.pid)
          break unless ret
        end
      end
    end
  end
end
