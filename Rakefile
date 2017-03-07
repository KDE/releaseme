# rubocop:disable Style/HashSyntax

def cond_require(lib, &block)
  require lib
  block.yield
rescue LoadError
  warn "E: #{lib} not found. Not providing related Rake task."
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.test_files = FileList.new('test/test_helper.rb')
  t.verbose = true
end

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  rdoc.rdoc_files.include('lib/*.rb')
end

cond_require 'yard' do
  desc 'Yard documentation'
  YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/*.rb']
    t.options = ['--any', '--extra', '--opts']
    t.stats_options = ['--list-undoc']
  end
end

cond_require 'rubocop/rake_task' do
  desc 'Run RuboCop on the lib directory'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.patterns = ['lib/*.rb']
    task.formatters = ['files']
    task.fail_on_error = false
  end
  task :quality => :rubocop
end

task :default => :test
