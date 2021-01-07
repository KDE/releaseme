#--
# Copyright (C) 2007-2020 Harald Sitter <sitter@kde.org>
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

require 'fileutils'
require 'open3'

require_relative 'logable'
require_relative 'vcs'

module ReleaseMe
  # Wrapper around Git.
  class Git < Vcs
    class CloneError < StandardError; end

    prepend Logable

    # Git branch to {#get} from, when nil no explicit argument is passed to git
    attr_accessor :branch

    # Git hash of the gotten source. This is nil unless get() finished
    # successfully
    # FIXME: might need to move to Vcs base?
    attr_reader :hash

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

    # FIXME: code dupe from svn, move to joint thingy, alas, logger is a bit in
    #   the way
    def debug_output(output)
      return if logger.level != Logger::DEBUG || output.empty?
      log_debug '-- output --'
      output.lines.each { |l| log_debug l.rstrip }
      log_debug '------------'
    end
  end
end
