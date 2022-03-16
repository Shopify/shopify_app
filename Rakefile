# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

require File.expand_path("../test/dummy/config/application", __FILE__)

# TODO: Remove this special test and replace with `Rails.application.load_tasks`
Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.libs << "test"
  t.verbose = false
  t.warning = false

  t.test_files = FileList["test/**/*_test.rb"]
    .exclude("test/shopify_app/managers/scripttags_manager_test.rb")
    .exclude("test/shopify_app/managers/webhooks_manager_test.rb")
end
