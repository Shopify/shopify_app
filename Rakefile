# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

require File.expand_path("../test/dummy/config/application", __FILE__)

Rails.application.load_tasks

# Clear the Rails-provided test task and define our own
Rake::Task["test"].clear if Rake::Task.task_defined?("test")

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = true
end

task default: :test
