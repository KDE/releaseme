# SPDX-FileCopyrightText: 2007-2020 Harald Sitter <sitter@kde.org>
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

require 'fileutils'
require 'open3'

require_relative 'logable'
require_relative 'vcs'

module ReleaseMe
  # Wrapper around Subversion.
  class Svn < Vcs
    prepend Logable

    class Error < StandardError
      RA_ILLEGAL_URL = 170000
      ILLEGAL_TARGET = 200009 # list/cat with invalid targets (target path doesnt exist)

      attr_reader :codes

      def initialize(codes, result)
        @codes = codes.uniq
        super(<<-EOF)
Unexpected SVN Errors

Please file a bug against releaseme for investigation at bugs.kde.org.
Chances are this is a server-side problem though.
You could try again in a couple minutes.

  cmd: #{result.cmd}
  status: #{result.status}
  error(s): #{codes.join(', ')}

    -- stdout --
#{result.out.rstrip}
    -- stderr --
#{result.err.rstrip}
    ------------
        EOF
      end
    end

    class Result
      attr_reader :cmd
      attr_reader :status
      attr_reader :out
      attr_reader :err

      def initialize(cmd)
        @cmd = cmd.freeze
      end

      def capture3(args)
        raise unless args.size == 3
        @out, @err, @status = *args
      end

      def success?
        @status.success?
      end

      def empty?
        out.empty? && err.empty?
      end

      def maybe_raise
        return if success?

        codes = []

        err.lines.each do |line|
          code = line.match(/^svn: E(?<code>\d+):.*/)&.[](:code)
          next if !code || code.empty?
          codes << code.to_i
        end

        raise Error.new(codes, self) unless codes.empty?
      end
    end

    # Checkout a path from the remote repository.
    # @param target is the target directory for the checkout
    # @param path is an additional path to append to the repo URL
    # @return [Boolean] whether the checkout was successful
    def get(target, path = nil, clean: false)
      url?(target)
      url = repository.dup # Deep copy since we will patch around
      url.concat("/#{path}") if path && !path.empty?
      _output, status = run(['co', url, target])
      clean!(target) if clean
      status.success?
    rescue Error => e
      raise e unless e.codes == [Error::RA_ILLEGAL_URL]
      false
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
      output, _status = run(['ls', url])
      output
    rescue Error => e
      raise e unless e.codes == [Error::ILLEGAL_TARGET]
      ''
    end

    # Concatenate to output.
    # @param file_path filepath to append to the repository URL
    # @return [String] content of cat'd path
    def cat(file_path)
      output, _status = run(['cat', "#{repository}/#{file_path}"])
      output
    rescue Error => e
      raise e unless e.codes == [Error::ILLEGAL_TARGET]
      ''
    end

    # Export single file from remote repository.
    # @param path filepath to append to the repository URL
    # @param targetFilePath target file path to write to
    # @return [Boolean] whether or not the export was successful
    def export(target, path)
      url?(target)
      _output, status = run(['export', "#{repository}/#{path}", target])
      status.success?
    rescue Error => e
      raise e unless e.codes == [Error::RA_ILLEGAL_URL]
      false
    end

    # Checks whether a file/dir exists on the remote repository
    # @param filePath filepath to append to the repository URL
    # @return [Boolean] whether or not the path exists
    def exist?(path)
      _output, status = run(['info', "#{repository}/#{path}"])
      status.success?
    rescue Error => e
      raise e unless e.codes == [Error::ILLEGAL_TARGET]
      false
    end

    def to_s
      "(svn - #{repository})"
    end

    private

    # @return [String, status] output of command
    def run(args)
      cmd = %w[svn] + args
      log_debug cmd.join(' ')
      result = Result.new(cmd)
      result.capture3(Open3.capture3({ 'LANG' => 'C.UTF-8' }, *cmd))
      debug_result(result)

      # for testing. we want to verify codes all the time so we need to track
      # the last most status somewhere. this must not be used for production
      # code that gets threaded.
      @status = result.status.dup

      result.maybe_raise
      # Do not return error output as it will screw with output processing.
      [result.success? ? result.out : '', result.status]
    end

    def debug_result(result)
      return if logger.level != Logger::DEBUG || result.empty?
      # log this in one go to be thread synchronized
      log_debug <<-OUTPUT

-- stdout #{result.status} --
#{result.out.lines.collect(&:rstrip).join("\n")}
-- stderr #{status} --
#{result.err.lines.collect(&:rstrip).join("\n")}
'------------'
      OUTPUT
    end

    def url?(path)
      if path.match('((\w|\W)+)://.*')
        log_warn 'possbily inverted argument order detected!'
        return true
      end
      false
    end

    # Calling this on the same instance of svn is not thread safe. Since we
    # only use it in tests it's marked private!
    # @return [ProcessStatus] exit status of last command that ran.
    attr_reader :status
  end
end
