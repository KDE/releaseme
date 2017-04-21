#--
# Copyright (C) 2007-2015 Harald Sitter <sitter@kde.org>
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

require_relative 'logable'
require_relative 'vcs'

module ReleaseMe
  # Wrapper around Subversion.
  class Svn < Vcs
    prepend Logable

    private

    # @return [String] output of command
    def run(args)
      cmd = "svn #{args.join(' ')} 2>&1"
      log_debug cmd
      output = `#{cmd}`
      unless logger.level != Logger::DEBUG || output.empty?
        log_debug '-- output --'
        output.lines.each { |l| log_debug l.rstrip }
        log_debug '------------'
      end
      # Do not return error output as it will screw with output processing.
      output = '' unless $?.success?
      output
    end

    def url?(path)
      if path.match('((\w|\W)+)://.*')
        log_warn 'possbily inverted argument order detected!'
        return true
      end
      false
    end

    public

    # Checkout a path from the remote repository.
    # @param target is the target directory for the checkout
    # @param path is an additional path to append to the repo URL
    # @return [Boolean] whether the checkout was successful
    def get(target, path = nil)
      url?(target)
      url = repository.dup # Deep copy since we will patch around
      url.concat("/#{path}") if path && !path.empty?
      run(['co', url, target])
      $?.success?
    end

    # Removes .svn recursively from target.
    def clean!(target)
      Dir.glob("#{target}/**/**/.svn").each { |d| FileUtils.rm_rf(d) }
    end

    # List content of a directory in the remote repository.
    # If path is nil the ls will be run on the @repository url.
    # @return [String] output of command if successful. $? is set to return value.
    def list(path = nil)
      url = repository.dup # Deep copy since we will patch around
      url.concat("/#{path}") if path && !path.empty?
      run(['ls', url])
    end

    # Concatenate to output.
    # @param file_path filepath to append to the repository URL
    # @return [String] content of cat'd path
    def cat(file_path)
      run(['cat', "#{repository}/#{file_path}"])
    end

    # Export single file from remote repository.
    # @param path filepath to append to the repository URL
    # @param targetFilePath target file path to write to
    # @return [Boolean] whether or not the export was successful
    def export(target, path)
      url?(target)
      run(['export', "#{repository}/#{path}", target])
      $?.success?
    end

    # Checks whether a file/dir exists on the remote repository
    # @param filePath filepath to append to the repository URL
    # @return [Boolean] whether or not the path exists
    def exist?(path)
      run(['info', "#{repository}/#{path}"])
      $?.success?
    end

    def to_s
      "(svn - #{repository})"
    end
  end
end
