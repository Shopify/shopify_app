# frozen_string_literal: true

require 'test_helper'

class ShopMockSessionStoreWithScopes < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorageWithScopes
end

module ShopifyApp
  class ShopSessionStorageWithScopesTest < ActiveSupport::TestCase
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_TOKEN = "1234567890qwertyuiop"
    TEST_MERCHANT_SCOPES = 'read_products, write_orders'

    test ".retrieve can retrieve shop session records by ID" do
      ShopMockSessionStoreWithScopes.stubs(:find_by).returns(MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        scopes: TEST_MERCHANT_SCOPES
      ))

      session = ShopMockSessionStoreWithScopes.retrieve(1)
      assert_equal TEST_SHOPIFY_DOMAIN, session.domain
      assert_equal TEST_SHOPIFY_TOKEN, session.token
      assert_equal ShopifyAPI::ApiAccess.new(TEST_MERCHANT_SCOPES), session.access_scopes
    end

    test ".retrieve_by_shopify_domain can retrieve shop session records by JWT" do
      instance = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        api_version: '2020-01',
        scopes: TEST_MERCHANT_SCOPES
      )
      ShopMockSessionStoreWithScopes.stubs(:find_by).with(shopify_domain: TEST_SHOPIFY_DOMAIN).returns(instance)

      expected_session = ShopifyAPI::Session.new(
        domain: instance.shopify_domain,
        token: instance.shopify_token,
        api_version: instance.api_version,
        access_scopes: instance.access_scopes
      )
      shopify_domain = TEST_SHOPIFY_DOMAIN

      session = ShopMockSessionStoreWithScopes.retrieve_by_shopify_domain(shopify_domain)
      assert_equal expected_session.domain, session.domain
      assert_equal expected_session.token, session.token
      assert_equal expected_session.api_version, session.api_version
      assert_equal expected_session.access_scopes, session.access_scopes
    end

    test ".store can store shop session records" do
      mock_shop_instance = MockShopInstance.new(id: 12345)
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStoreWithScopes.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:domain).returns(mock_shop_instance.shopify_domain)
      mock_auth_hash.stubs(:token).returns("a-new-token!")
      mock_auth_hash.stubs(:access_scopes).returns(ShopifyAPI::ApiAccess.new(TEST_MERCHANT_SCOPES))
      saved_id = ShopMockSessionStoreWithScopes.store(mock_auth_hash)

      assert_equal "a-new-token!", mock_shop_instance.shopify_token
      assert_equal mock_shop_instance.id, saved_id
    end

    test '.retrieve returns nil for non-existent shop' do
      shop_id = 'non-existent-id'
      ShopMockSessionStoreWithScopes.stubs(:find_by).with(id: shop_id).returns(nil)

      refute ShopMockSessionStoreWithScopes.retrieve(shop_id)
    end

    test '.retrieve_by_shopify_domain returns nil for non-existent shop' do
      shop_domain = 'non-existent-id'

      ShopMockSessionStoreWithScopes.stubs(:find_by).with(shopify_domain: shop_domain).returns(nil)

      refute ShopMockSessionStoreWithScopes.retrieve_by_shopify_domain(shop_domain)
    end

    test '.retrieve throws NotImplementedError when access_scopes getter is not implemented' do
      mock_shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN
      )
      mock_shop.stubs(:access_scopes).raises(NotImplementedError)
      ShopMockSessionStoreWithScopes.stubs(:find_by).returns(mock_shop)

      assert_raises NotImplementedError do
        ShopMockSessionStoreWithScopes.retrieve(1)
      end
    end
  end
end
