# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2007-2020 Harald Sitter <sitter@kde.org>

require 'fileutils'
require 'open3'

require_relative 'logable'

module ReleaseMe
  # Wrapper around Git.
  class Git
    class CloneError < StandardError; end

    prepend Logable

    # The repository URL
    attr_accessor :repository

    # Git branch to {#get} from, when nil no explicit argument is passed to git
    attr_accessor :branch

    # Git hash of the gotten source. This is nil unless get() finished
    # successfully
    # FIXME: might need to move to Vcs base?
    attr_reader :hash

    # Construct a VCS instance from a hash defining its attributes.
    # FIXME: why is this not simply an init? Oo
    def self.from_hash(hash)
      vcs = new
      hash.each do |key, value|
        vcs.send("#{key}=".to_sym, value)
      end
      vcs
    end

    # Clones repository into target directory
    # @param shallow whether or not to create a shallow clone
    # @return [Boolean] success
    # FIXME: return actually not implemented, hrrhrr
    # FIXME: make shallow a keyword
    def get(target, shallow = true, clean: false)
      args = %w[clone]
      args << '--depth' << '1' if shallow
      args << "--branch" << branch unless branch.nil? || branch.empty?
      args += [repository, target]
      output, status = run(args)
      raise CloneError, output unless status.success?
      # Set hash accordingly
      Dir.chdir(target) do
        @hash = `git rev-parse HEAD`.chop
      end
      clean!(target) if clean
      status.success?
    end

    # Removes target/.git.
    def clean!(target)
      FileUtils.rm_rf("#{target}/.git")
    end

    def to_s
      "(git - #{repository} [#{branch || 'master'}])"
    end

    # @return true if ls-remote succeeds on the repo
    def exist?
      _output, status = run(['ls-remote', repository])
      status.success?
    end

    private

    # @return [String, status] output of command
    def run(args)
      cmd = %w[git] + args
      log_debug cmd.join(' ')
      output, status = Open3.capture2e(*cmd)
      # for testing. we want to verify codes all the time so we need to track
      # the last most status somewhere. this must not be used for production
      # code that gets threaded.
      @status = status.freeze
      debug_output(output)
      # Do not return error output as it will screw with output processing.
      [output, status]
    end

    def debug_output(output)
      return if logger.level != Logger::DEBUG || output.empty?
      log_debug '-- output --'
      output.lines.each { |l| log_debug l.rstrip }
      log_debug '------------'
    end
  end
end
