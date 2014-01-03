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

require_relative 'vcs'

class Svn < Vcs
private
    def url?(path)
        if path.match('((\w|\W)+)://.*')
            puts "SVN: possbily inversed argument order detected!"
            return true
        end
        return false
    end

public
    ##
    # call-seq:
    #  svn.get(target directory, path to check out) -> true or false
    #
    # Checkout a path from the remote repository.
    # @param target is the target directory for the checkout
    # @param path is an additional path to append to the repo URL
    # @returns boolean whether the checkout was successful
    def get(target, path = nil)
        url?(target)
        url = repository.dup # Deep copy since we will patch around
        if not path.nil? and not path.empty?
            url.concat("/#{path}")
        end
        return system("svn co #{url} #{target}")
    end

    ##
    # call-seq:
    #  svn.list(path) -> string
    #
    # List content of a directory in the remote repository.
    # If path is nil the ls will be run on the @repository url.
    # Returns output of ls command if successful. $? is set to return value.
    def list(path = nil)
        url = repository.dup # Deep copy since we will patch around
        if not path.nil? and not path.empty?
            url.concat("/#{path}")
        end
        return %x[svn ls #{url}]
    end

    ##
    # call-seq:
    #  svn.cat(file path to cat) -> string
    #
    # Concatenate to output.
    # @param filePath filepath to append to the repository URL
    # @returns content of cat'd file as string
    def cat(filePath)
        return %x[svn cat #{repository}/#{filePath}]
    end

    ##
    # call-seq:
    #  svn.export(target path/file, path to export) -> true or false
    #
    # Export single file from remote repository.
    # @param path filepath to append to the repository URL
    # @param targetFilePath target file path to write to
    # @returns boolean whether or not the export was successful
    def export(target, path)
        url?(target)
        return system("svn export #{repository}/#{path} #{target}")
    end
    ##
    # call-seq:
    #  svn.exists?(path) -> true or false
    #
    # Checks whether a file/dir exists on the remote repository
    # @param filePath filepath to append to the repository URL
    # @returns boolean whether or not the path exists
    def exist?(path)
        return system("svn info #{repository}/#{path}")
    end
end
