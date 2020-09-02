# frozen_string_literal: true
require 'test_helper'
require 'generators/shopify_app/user_model/user_model_generator'

class UserModelGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::UserModelGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    prepare_destination
    provide_existing_initializer_file
  end

  test "create the user model" do
    run_generator
    assert_file "app/models/user.rb" do |user|
      assert_match "class User < ActiveRecord::Base", user
      assert_match "include ShopifyApp::UserSessionStorage", user
      assert_match(/def api_version\n\s*ShopifyApp\.configuration\.api_version\n\s*end/, user)
    end
  end

  test "creates UserModel migration" do
    run_generator
    assert_migration "db/migrate/create_users.rb" do |migration|
      assert_match "create_table :users do |t|", migration
    end
  end

  test "updates the shopify_app initializer to use User to store session" do
    run_generator
    assert_file "config/initializers/shopify_app.rb" do |file|
      assert_match "config.user_session_repository = 'User'", file
    end
  end

  test "creates default user fixtures" do
    run_generator
    assert_file "test/fixtures/users.yml" do |file|
      assert_match "regular_user:", file
    end
  end
end
