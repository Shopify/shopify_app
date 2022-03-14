# frozen_string_literal: true

require "test_helper"
require "generators/shopify_app/shop_model/shop_model_generator"

class ShopModelGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::ShopModelGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    prepare_destination
    provide_existing_initializer_file
  end

  test "create the shop model" do
    run_generator
    assert_file "app/models/shop.rb" do |shop|
      assert_match "class Shop < ActiveRecord::Base", shop
      assert_match "include ShopifyApp::ShopSessionStorageWithScopes", shop
      assert_match(/def api_version\n\s*ShopifyApp\.configuration\.api_version\n\s*end/, shop)
    end
  end

  test "creates ShopModel migration" do
    run_generator
    assert_migration "db/migrate/create_shops.rb" do |migration|
      assert_match "create_table :shops  do |t|", migration
    end
  end

  test "create shop with access_scopes migration in a test environment" do
    run_generator
    assert_migration "db/migrate/add_shop_access_scopes_column.rb" do |migration|
      assert_match "add_column :shops, :access_scopes, :string", migration
    end
  end

  test "create shop with access_scopes migration with --new-shopify-cli-app flag provided" do
    Rails.env = "mock_environment"

    run_generator ["--new-shopify-cli-app"]
    Rails.env = "test" # Change this back for subsequent tests

    assert_migration "db/migrate/add_shop_access_scopes_column.rb" do |migration|
      assert_match "add_column :shops, :access_scopes, :string", migration
    end
  end

  test "updates the shopify_app initializer" do
    run_generator
    assert_file "config/initializers/shopify_app.rb" do |file|
      assert_match "config.shop_session_repository = 'Shop'", file
    end
  end

  test "creates default shop fixtures" do
    run_generator
    assert_file "test/fixtures/shops.yml" do |file|
      assert_match "regular_shop:", file
    end
  end
end
