# frozen_string_literal: true
require 'test_helper'

class ShopMockSessionStore < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorage
end

module ShopifyApp
  class ShopSessionStorageTest < ActiveSupport::TestCase
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_TOKEN = "1234567890qwertyuiop"

    setup do
      ShopifyApp.configuration.scopes_exist_on_shop = false
      ShopifyApp.configuration.shop_session_repository = 'Shop'
    end

    test ".retrieve can retrieve shop session records by ID" do
      ShopMockSessionStore.stubs(:find_by).returns(MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN
      ))

      session = ShopMockSessionStore.retrieve(1)
      assert_equal TEST_SHOPIFY_DOMAIN, session.domain
      assert_equal TEST_SHOPIFY_TOKEN, session.token
    end

    test ".retrieve_by_shopify_domain can retrieve shop session records by JWT" do
      instance = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        api_version: '2020-01',
      )
      ShopMockSessionStore.stubs(:find_by).with(shopify_domain: TEST_SHOPIFY_DOMAIN).returns(instance)

      expected_session = ShopifyAPI::Session.new(
        domain: instance.shopify_domain,
        token: instance.shopify_token,
        api_version: instance.api_version,
      )
      shopify_domain = TEST_SHOPIFY_DOMAIN

      session = ShopMockSessionStore.retrieve_by_shopify_domain(shopify_domain)
      assert_equal expected_session.domain, session.domain
      assert_equal expected_session.token, session.token
      assert_equal expected_session.api_version, session.api_version
    end

    test ".store can store shop session records" do
      mock_shop_instance = MockShopInstance.new(id: 12345)
      mock_scopes = %w(read_orders write_customers)
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:domain).returns(mock_shop_instance.shopify_domain)
      mock_auth_hash.stubs(:token).returns("a-new-token!")
      saved_id = ShopMockSessionStore.store(mock_auth_hash)

      assert_equal "a-new-token!", mock_shop_instance.shopify_token
      assert_nil mock_shop_instance.scopes
      assert_equal mock_shop_instance.id, saved_id
    end

    test '.retrieve returns nil for non-existent shop' do
      shop_id = 'non-existent-id'
      ShopMockSessionStore.stubs(:find_by).with(id: shop_id).returns(nil)

      refute ShopMockSessionStore.retrieve(shop_id)
    end

    test '.retrieve_by_shopify_domain returns nil for non-existent shop' do
      shop_domain = 'non-existent-id'

      ShopMockSessionStore.stubs(:find_by).with(shopify_domain: shop_domain).returns(nil)

      refute ShopMockSessionStore.retrieve_by_shopify_domain(shop_domain)
    end

    test '.store can store scopes if scopes_exist_on_shop is true' do
      ShopifyApp.configuration.scopes_exist_on_shop = true
      mock_shop_instance = MockShopInstance.new(id: 12345)
      mock_scopes = %w(read_orders write_customers)
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:domain).returns(mock_shop_instance.shopify_domain)
      mock_auth_hash.stubs(:token).returns("a-new-token!")

      saved_id = ShopMockSessionStore.store_with_scopes(mock_auth_hash, mock_scopes)

      assert_equal "a-new-token!", mock_shop_instance.shopify_token
      assert_equal mock_scopes, mock_shop_instance.scopes
      assert_equal mock_shop_instance.id, saved_id
    end
  end
end
