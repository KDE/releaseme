# coding: utf-8
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2017-2020 Harald Sitter <sitter@kde.org>

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name        = 'releaseme'
  spec.version     = '0.0'
  spec.authors     = ['Harald Sitter']
  spec.email       = ['sitter@kde.org']

  spec.summary     = 'KDE tarball release tool'
  spec.description = 'Helps with releasing KDE software as source code tarballs'
  spec.homepage    = 'https://phabricator.kde.org/source/releaseme/'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the
  # 'allowed_push_host' to allow pushing to a single host or delete this section
  # to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0")
  rejected_files = spec.files.find_all do |f|
    f.match(%r{^(test|spec|features)/}) ||
    (f.match(%r{^lib/[^/]+.rb}) && !f.match(%r{^lib/releaseme.rb}))
  end
  spec.files -= rejected_files

  # When run through bundler AND in a Gem search path mangle the working
  # directory.
  if File.basename($PROGRAM_NAME).include?('bundle') &&
     (Gem.path.any? { |x| Dir.pwd.start_with?(x) } ||
      Dir.pwd.include?('.bundler/') || Dir.pwd.include?('.bundle/'))
    warn "Mangling releaseme gem as it is in a gem search path #{Dir.pwd}"
    FileUtils.rm_rf(rejected_files, verbose: true)
  end

  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  # Development
  spec.add_development_dependency 'rake', '>= 12.3.3'
  # Documentation
  spec.add_development_dependency 'rdoc'
  spec.add_development_dependency 'yard'
  # Testing
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'webmock'
  # Coverage
  spec.add_development_dependency 'simplecov', '>= 0.11'
  # Quality
  spec.add_development_dependency 'rubocop', '~> 0.84.0'
end
