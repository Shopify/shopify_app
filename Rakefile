# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

require File.expand_path("../test/dummy/config/application", __FILE__)

Rails.application.load_tasks

# Clear Rails' test task which expects bin/rails to exist.
# This gem uses a dummy Rails app for testing but doesn't have bin/rails
# since it's a gem, not a standalone Rails application.
Rake::Task["test"].clear if Rake::Task.task_defined?("test")

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = true
end

task default: :test
