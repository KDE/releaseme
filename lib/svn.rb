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
    # Svn checkout
    # @param target is the target directory for the checkout
    # @param path is an additional path to append to the repo URL
    # @returns boolean whether the checkout was successful
    def get(target, path = nil)
        url = repository.dup # Deep copy since we will patch around
        if not path.nil? and not path.empty?
            url.concat("/#{path}")
        end
        return %x{svn co #{url} #{target}}
    end

    # Svn ls
    # @param path a path to append to the repository url (if any)
    # @returns output of ls command
    def list(path = nil)
        url = repository.dup # Deep copy since we will patch around
        if not path.nil? and not path.empty?
            url.concat("/#{path}")
        end
        return %x[svn ls #{url}]
    end

    # Svn cat
    # @param filePath filepath to append to the repository URL
    # @returns content of cat'd file as string
    def cat(filePath)
        return %x[svn cat #{repository}/#{filePath}]
    end

    # Svn export
    # @param filePath filepath to append to the repository URL
    # @param targetFilePath target file path to write to
    # @returns boolean whether or not the export was successful
    def export(filePath, targetFilePath)
        return %x[svn export #{repository}/#{filePath} #{targetFilePath}]
    end

    # Checks whether a file/dir exists on the remote repository
    # @param filePath filepath to append to the repository URL
    # @returns boolean whether or not the path exists
    def exists?(filePath)
        return %x[svn info #{repository}/#{filePath}]
    end
end
