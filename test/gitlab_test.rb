# frozen_string_literal: true

# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2017-2022 Harald Sitter <sitter@kde.org>

require 'fileutils'

require_relative 'lib/testme'
require_relative '../lib/releaseme/gitlab'

class TestGitLab < Testme
  def teardown
    WebMock.reset!
    ENV.delete('RELEASEME_CI_CHECK')
  end

  def new_connection
    ReleaseMe::GitLab::Connection.new
  end

  def test_from_name_and_branch
    stub_request(:get, 'https://invent.kde.org/api/v4/projects/utilities%2Fyakuake/pipelines?page=0&ref=master')
      .to_return(body: <<~JSON)
        [
          {"id":210853,"iid":141,"project_id":2823,"sha":"ad9819d56839ba0380fafad97d2ca043f9424b59","ref":"master","status":"skipped","source":"push","created_at":"2022-07-31T01:53:32.240Z","updated_at":"2022-07-31T01:53:32.240Z","web_url":"https://invent.kde.org/utilities/yakuake/-/pipelines/210853"}
        ]
      JSON
    stub_request(:get, 'https://invent.kde.org/api/v4/projects/utilities%2Fyakuake/pipelines?page=1&ref=master')
      .to_return(body: <<~JSON)
        [
          {"id":209072,"iid":140,"project_id":2823,"sha":"79e4a8166394efcb772eea55cab871c37e239231","ref":"master","status":"success","source":"push","created_at":"2022-07-25T23:46:53.398Z","updated_at":"2022-07-25T23:47:36.958Z","web_url":"https://invent.kde.org/utilities/yakuake/-/pipelines/209072"}
        ]
      JSON

    pipeline_count = 0
    ReleaseMe::GitLab::Pipeline.each_from_repository_and_branch('git@invent.kde.org:utilities/yakuake', 'master') do |x|
      pipeline_count += 1
      assert_equal('79e4a8166394efcb772eea55cab871c37e239231', x['sha'])
    end
    assert_equal(1, pipeline_count)
  end
end
