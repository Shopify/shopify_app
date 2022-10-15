# frozen_string_literal: true

require "test_helper"

class ShopMockSessionStore < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorage
end

module ShopifyApp
  class ShopSessionStorageTest < ActiveSupport::TestCase
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_TOKEN = "1234567890qwertyuiop"

    test ".retrieve can retrieve shop session records by ID" do
      ShopMockSessionStore.stubs(:find_by).returns(MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
      ))

      session = ShopMockSessionStore.retrieve(1)
      assert_equal TEST_SHOPIFY_DOMAIN, session.shop
      assert_equal TEST_SHOPIFY_TOKEN, session.access_token
    end

    test ".retrieve_by_shopify_domain can retrieve shop session records by JWT" do
      instance = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
      )
      ShopMockSessionStore.stubs(:find_by).with(shopify_domain: TEST_SHOPIFY_DOMAIN).returns(instance)

      expected_session = ShopifyAPI::Auth::Session.new(
        shop: instance.shopify_domain,
        access_token: instance.shopify_token,
      )
      shopify_domain = TEST_SHOPIFY_DOMAIN

      session = ShopMockSessionStore.retrieve_by_shopify_domain(shopify_domain)
      assert_equal expected_session.shop, session.shop
      assert_equal expected_session.access_token, session.access_token
    end

    test ".store can store shop session records" do
      mock_shop_instance = MockShopInstance.new(id: 12345)
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:shop).returns(mock_shop_instance.shopify_domain)
      mock_auth_hash.stubs(:access_token).returns("a-new-token!")
      mock_auth_hash.stubs(:scope).returns(ShopifyAPI::Auth::AuthScopes.new("read_products,write_orders"))
      saved_id = ShopMockSessionStore.store(mock_auth_hash)

      assert_equal "a-new-token!", mock_shop_instance.shopify_token
      assert_equal mock_shop_instance.id, saved_id
    end

    test ".retrieve returns nil for non-existent shop" do
      shop_id = "non-existent-id"
      ShopMockSessionStore.stubs(:find_by).with(id: shop_id).returns(nil)

      refute ShopMockSessionStore.retrieve(shop_id)
    end

    test ".retrieve_by_shopify_domain returns nil for non-existent shop" do
      shop_domain = "non-existent-id"

      ShopMockSessionStore.stubs(:find_by).with(shopify_domain: shop_domain).returns(nil)

      refute ShopMockSessionStore.retrieve_by_shopify_domain(shop_domain)
    end
  end
end
