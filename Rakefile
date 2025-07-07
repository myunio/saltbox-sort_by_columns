# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)

task default: [:spec, :standard]

desc "Run StandardRB linter"
task :standard do
  sh "standardrb"
end

desc "Run StandardRB linter with auto-fix"
task :standard_fix do
  sh "standardrb --fix"
end

desc "Build the gem"
task :build do
  sh "gem build sort_by_columns.gemspec"
end

desc "Install the gem locally"
task :install do
  sh "gem build sort_by_columns.gemspec"
  sh "gem install sort_by_columns-*.gem"
end

desc "Clean up build artifacts"
task :clean do
  sh "rm -f *.gem"
end
