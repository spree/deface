require 'rake'
require 'rubygems'
require 'rake/testtask'
require 'rdoc/task'
require 'rspec'
require 'rspec/core/rake_task'

require 'bundler'
Bundler.require
Bundler::GemHelper.install_tasks

desc 'Default: run specs'
task :default => :spec
RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end
