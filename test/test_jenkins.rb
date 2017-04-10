#--
# Copyright (C) 2017 Harald Sitter <sitter@kde.org>
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

require_relative 'lib/testme'
require_relative '../lib/releaseme/jenkins'

require 'webmock/test_unit'

class TestJenkins < Testme
  def teardown
    WebMock.reset!
  end

  def new_connection
    ReleaseMe::Jenkins::Connection.new
  end

  def test_from_name_and_branch
    stub_request(:get, 'https://build.kde.org/api/json?tree=jobs%5Bname,url%5D,views%5Bname%5D')
      .to_return(body: JSON.generate(
        jobs: [
          {
            name: 'yakuake master kf5-qt5',
            url: 'https://build.kde.org/job/yakuake%20master%20kf5-qt5/'
          },
          {
            name: 'yakuake fly kf5-qt5',
            url: 'NOT EXPECTING WRONG BRANCH'
          },
          {
            name: 'fruit master kf5-qt5',
            url: 'NOT EXPECTING WRONG NAME'
          }
        ]
      ))

    jobs = ReleaseMe::Jenkins::Job.from_name_and_branch('yakuake', 'master')
    assert_equal(1, jobs.size)
    assert_equal('https://build.kde.org/job/yakuake%20master%20kf5-qt5/', jobs[0].url)
  end

  def test_bad_jobs
    stub_request(:get, 'https://build.kde.org/api/json?tree=jobs%5Bname,url%5D,views%5Bname%5D')
      .to_return(body: JSON.generate(
        jobs: [
          {
            name: 'yakuake master kf5-qt5',
            url: 'https://build.kde.org/job/yakuake%20master%20kf5-qt5/'
          },
          {
            name: 'yakuake fly kf5-qt5',
            url: 'NOT EXPECTING WRONG BRANCH'
          },
          {
            name: 'fruit master kf5-qt5',
            url: 'NOT EXPECTING WRONG NAME'
          }
        ]
      ))

    # Returns?
    jobs = ReleaseMe::Jenkins::Job.bad_jobs('yakuake', 'master')
    assert_equal(1, jobs.size)

    # Yields?
    called = 0
    ReleaseMe::Jenkins::Job.bad_jobs('yakuake', 'master') { called += 1 }
    assert_equal(1, called)
  end

  def test_job
    stub_request(:get, 'https://build.kde.org/job/xx/api/json')
      .to_return(body: JSON.generate(displayName: 'meow meow'))

    job = ReleaseMe::Jenkins::Job.new('https://build.kde.org/job/xx/', new_connection)

    assert_equal('meow meow', job.display_name)
    assert_equal('/job/xx/lastBuild',
                 job.last_build.path.to_s)
    assert_equal('/job/xx/lastStableBuild',
                 job.last_stable_build.path.to_s)
    assert_equal('/job/xx/lastSuccessfulBuild',
                 job.last_successful_build.path.to_s)
  end

  def test_build_equal
    stub_request(:get, 'https://build.kde.org/job/xx/lastBuild/api/json')
      .to_return(body: JSON.generate(id: 17))
    stub_request(:get, 'https://build.kde.org/job/xx/lastSuccessfulBuild/api/json')
      .to_return(body: JSON.generate(id: 17))
    stub_request(:get, 'https://build.kde.org/job/xx/lastStableBuild/api/json')
      .to_return(body: JSON.generate(id: 16))

    job = ReleaseMe::Jenkins::Job.new('https://build.kde.org/job/xx/', new_connection)
    build = job.last_build
    successful_build = job.last_successful_build
    stable_build = job.last_stable_build
    assert_equal(17, build.id)
    assert_equal(17, successful_build.id) # 17 became unstable
    assert_equal(16, stable_build.id) # 16 was still stable
    assert(build == successful_build)
    assert(build != stable_build)
    assert(successful_build != stable_build)

    ENV.delete('RELEASEME_CI_CHECK')
    assert_false(job.sufficient_quality?)
    ENV['RELEASEME_CI_CHECK'] = 'success'
    assert(job.sufficient_quality?)
    ENV['RELEASEME_CI_CHECK'] = 'none'
    assert(job.sufficient_quality?)
  end

  def test_build_equal_raise
    stub_request(:get, 'https://build.kde.org/job/xx/lastBuild/api/json')
      .to_return(body: JSON.generate(id: 17))
    stub_request(:get, 'https://build.kde.org/job/xx/lastSuccessfulBuild/api/json')
      .to_return(status: 404)
    stub_request(:get, 'https://build.kde.org/job/xx/lastStableBuild/api/json')
      .to_return(status: 404)

    job = ReleaseMe::Jenkins::Job.new('https://build.kde.org/job/xx/', new_connection)
    assert_false(job.last_successful_build == job.last_build)
    assert_false(job.last_stable_build == job.last_build)
    assert_false(job.last_stable_build == job.last_successful_build)
  end
end
