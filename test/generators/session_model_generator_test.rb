# frozen_string_literal: true
require 'test_helper'
require 'generators/shopify_app/session_model/session_model_generator'

class SessionModelGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::SessionModelGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    prepare_destination
    provide_existing_initializer_file
  end

  test "create the session model" do
    run_generator
    assert_file "app/models/session.rb" do |session|
      assert_match "class Session < ActiveRecord::Base", session
      assert_match "include ShopifyApp::ActualSessionStorage", session
      assert_match(/def api_version\n\s*ShopifyApp\.configuration\.api_version\n\s*end/, session)
    end
  end

  test "creates SessionModel migration" do
    run_generator
    assert_migration "db/migrate/create_sessions.rb" do |migration|
      assert_match "create_table :sessions do |t|", migration
    end
  end

  test "creates default session fixtures" do
    run_generator
    assert_file "test/fixtures/sessions.yml" do |file|
      assert_match "regular_session:", file
    end
  end
end
