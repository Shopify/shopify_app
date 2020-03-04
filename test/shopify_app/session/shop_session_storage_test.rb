require 'test_helper'

class ShopMockSessionStore < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorage
end

module ShopifyApp
  class ShopSessionStorageTest < ActiveSupport::TestCase
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_TOKEN = "1234567890qwertyuiop"

    test ".retrieve can retrieve shop session records by ID" do
      ShopMockSessionStore.stubs(:find_by).returns(MockShopInstance.new(
        shopify_domain:TEST_SHOPIFY_DOMAIN,
        shopify_token:TEST_SHOPIFY_TOKEN
      ))

      session = ShopMockSessionStore.retrieve(id=1)
      assert_equal TEST_SHOPIFY_DOMAIN, session.domain
      assert_equal TEST_SHOPIFY_TOKEN, session.token
    end

    test ".retrieve_by_jwt can retrieve shop session records by JWT" do
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

      payload = { 'dest' => TEST_SHOPIFY_DOMAIN }
      session = ShopMockSessionStore.retrieve_by_jwt(payload)
      assert_equal expected_session.domain, session.domain
      assert_equal expected_session.token, session.token
      assert_equal expected_session.api_version, session.api_version
    end

    test ".store can store shop session records" do
      mock_shop_instance = MockShopInstance.new(id:12345)
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock()
      mock_auth_hash.stubs(:domain).returns(mock_shop_instance.shopify_domain)
      mock_auth_hash.stubs(:token).returns("a-new-token!")
      saved_id = ShopMockSessionStore.store(mock_auth_hash)

      assert_equal "a-new-token!", mock_shop_instance.shopify_token
      assert_equal mock_shop_instance.id, saved_id
    end

    test '.retrieve returns nil for non-existent shop' do
      shop_id = 'non-existent-id'
      ShopMockSessionStore.stubs(:find_by).with(id: shop_id).returns(nil)

      refute ShopMockSessionStore.retrieve(shop_id)
    end

    test '.retrieve_by_jwt returns nil for non-existent shop' do
      shop_id = 'non-existent-id'
      payload = { 'dest' => shop_id }

      ShopMockSessionStore.stubs(:find_by).with(shopify_domain: payload['dest']).returns(nil)

      refute ShopMockSessionStore.retrieve_by_jwt(payload)
    end
  end
end
