# frozen_string_literal: true
require 'bundler/gem_tasks'
require 'rake/testtask'

require File.expand_path('../test/dummy/config/application', __FILE__)

# TODO: Remove this special test and replace with `Rails.application.load_tasks`
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.verbose = false
  t.warning = false

  t.test_files = FileList["test/**/*_test.rb"]
    .exclude("test/controllers/concerns/authenticated_test.rb")
    .exclude("test/controllers/callback_controller_test.rb")
    .exclude("test/controllers/sessions_controller_test.rb")
    .exclude("test/shopify_app/access_scopes/shop_strategy_test.rb")
    .exclude("test/shopify_app/access_scopes/user_strategy_test.rb")
    .exclude("test/shopify_app/controller_concerns/csrf_protection_test.rb")
    .exclude("test/shopify_app/controller_concerns/login_protection_test.rb")
    .exclude("test/shopify_app/jobs/scripttags_manager_job_test.rb")
    .exclude("test/shopify_app/managers/webhooks_manager_test.rb")
    .exclude("test/shopify_app/managers/scripttags_manager_test.rb")
    .exclude("test/shopify_app/session/session_repository_test.rb")
    .exclude("test/shopify_app/session/shop_session_storage_with_scopes_test.rb")
    .exclude("test/shopify_app/session/user_session_storage_with_scopes_test.rb")
    .exclude("test/shopify_app/session/shop_session_storage_test.rb")
    .exclude("test/shopify_app/session/user_session_storage_test.rb")
    .exclude("test/routes/sessions_routes_test.rb")
    .exclude("test/routes/callback_routes_test.rb")
end
