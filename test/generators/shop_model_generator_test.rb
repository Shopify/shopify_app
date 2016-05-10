require 'test_helper'
require 'generators/shopify_app/shop_model/shop_model_generator'

class ShopModelGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::ShopModelGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    prepare_destination
    provide_existing_authenticated_controller
  end

  test "create the shop model" do
    run_generator
    assert_file "app/models/shop.rb" do |shop|
      assert_match "class Shop < ActiveRecord::Base", shop
      assert_match "include ShopifyApp::Shop", shop
      assert_match "include ShopifyApp::SessionStorage", shop
    end
  end

  test "creates ShopModel migration" do
    run_generator
    assert_migration "db/migrate/create_shops.rb" do |migration|
      assert_match "create_table :shops do |t|", migration
    end
  end

  test "injects into authenticated controller" do
    run_generator
    assert_file "app/controllers/shopify_app/authenticated_controller.rb" do |controller|
      assert_match "def shop", controller
    end
  end

  test "adds the shopify_session_repository initializer" do
    run_generator
    assert_file "config/initializers/shopify_session_repository.rb" do |file|
      assert_match "ShopifyApp::SessionRepository.storage = Shop", file
    end
  end

  test "creates default shop fixtures" do
    run_generator
    assert_file "test/fixtures/shops.yml" do |file|
      assert_match "regular_shop:", file
    end
  end

end
