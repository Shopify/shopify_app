require 'test_helper'


module ShopifyApp
  class ShopStorageStrategyTest < ActiveSupport::TestCase

    test "tests that session store can retrieve shop session records" do
      TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
      TEST_SHOPIFY_TOKEN = "1234567890qwertyuiop"

      mock_shop_class = Object.new

      mock_shop_class.stubs(:find_by).returns(MockShopInstance.new(
        shopify_domain:TEST_SHOPIFY_DOMAIN,
        shopify_token:TEST_SHOPIFY_TOKEN
      ))
      ShopifyApp::SessionStorage::ShopStorageStrategy.const_set("Shop", mock_shop_class)

      begin
        ShopifyApp.configuration.per_user_tokens = false
        session = MockSessionStore.retrieve(id=1)

        assert_equal TEST_SHOPIFY_DOMAIN, session.domain
        assert_equal TEST_SHOPIFY_TOKEN, session.token
      ensure
        ShopifyApp.configuration.per_user_tokens = false
      end

      ShopifyApp::SessionStorage::ShopStorageStrategy.send(:remove_const , "Shop")
    end

    test "tests that session store can store shop session records" do
      mock_shop_instance = MockShopInstance.new(id:12345)
      mock_shop_instance.stubs(:save!).returns(true)

      mock_shop_class = Object.new
      mock_shop_class.stubs(:find_or_initialize_by).returns(mock_shop_instance)
    
      ShopifyApp::SessionStorage::ShopStorageStrategy.const_set("Shop", mock_shop_class)

      begin
        ShopifyApp.configuration.per_user_tokens = false
        
        mock_auth_hash = mock()
        mock_auth_hash.stubs(:domain).returns(mock_shop_instance.shopify_domain)
        mock_auth_hash.stubs(:token).returns("a-new-token!")
        saved_id = MockSessionStore.store(mock_auth_hash)

        assert_equal "a-new-token!", mock_shop_instance.shopify_token
        assert_equal mock_shop_instance.id, saved_id

      ensure
        ShopifyApp.configuration.per_user_tokens = false
      end
      ShopifyApp::SessionStorage::ShopStorageStrategy.send(:remove_const , "Shop")
    end
  end
end
