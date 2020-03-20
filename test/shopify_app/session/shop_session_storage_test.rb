# typed: false
require 'test_helper'

class ShopMockSessionStore < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorage
end

module ShopifyApp
  class ShopSessionStorageTest < ActiveSupport::TestCase
    test "tests that session store can retrieve shop session records" do
      TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
      TEST_SHOPIFY_TOKEN = "1234567890qwertyuiop"

      ShopMockSessionStore.stubs(:find_by).returns(MockShopInstance.new(
        shopify_domain:TEST_SHOPIFY_DOMAIN,
        shopify_token:TEST_SHOPIFY_TOKEN
      ))

      session = ShopMockSessionStore.retrieve(id=1)
      assert_equal TEST_SHOPIFY_DOMAIN, session.domain
      assert_equal TEST_SHOPIFY_TOKEN, session.token
    end

    test "tests that session store can store shop session records" do
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
  end
end
