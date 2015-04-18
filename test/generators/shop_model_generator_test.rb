require 'test_helper'
require 'generators/shopify_app/shop_model/shop_model_generator'

class ShopModelGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::ShopModelGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))
  setup :prepare_destination

  test "create the shop model" do
    run_generator
    assert_file "app/models/shop.rb" do |shop|
      assert_match "class Shop < ActiveRecord::Base", shop
      assert_match "include ShopifyApp::Shop", shop
    end
  end

  test "creates ShopModel migration" do
    run_generator
    assert_migration "db/migrate/create_shops.rb" do |migration|
      assert_match "create_table :shops  do |t|", migration
    end
  end

  test "adds the session_storage model" do
    run_generator
    assert_file "app/models/session_storage.rb" do |session_storage|
      assert_match "class SessionStorage", session_storage
      assert_match "def self.store(session)", session_storage
      assert_match " def self.retrieve(id)", session_storage
    end
  end

  test "adds the shopify_session_repository initializer" do
    run_generator
    assert_file "config/initializers/shopify_session_repository.rb" do |file|
      assert_match "ShopifyApp::SessionRepository.storage = SessionStorage", file
    end
  end

end
