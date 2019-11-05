require 'test_helper'


module ShopifyApp
  class ShopStorageStrategyTest < ActiveSupport::TestCase
  
    test "tests that ShopStorageStrategy is used for session storage" do
      begin
        ShopifyApp.configuration.per_user_tokens = false

        assert_equal MockSessionStore.strategy_klass, ShopifyApp::SessionStorage::ShopStorageStrategy
      ensure
        ShopifyApp.configuration.per_user_tokens = false
      end
    end

    test "tests that session store can retrieve shop session records" do
      TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
      TEST_SHOPIFY_TOKEN = "1234567890qwertyuiop"

      MockShopClass = mock()
      mmm = MockShopInstance.new(
        shopify_domain:TEST_SHOPIFY_DOMAIN,
        shopify_token:TEST_SHOPIFY_TOKEN
      )

      MockShopClass.stubs(:find_by).returns(mmm)
      ShopifyApp::SessionStorage::ShopStorageStrategy.const_set("Shop", MockShopClass)

      begin
        ShopifyApp.configuration.per_user_tokens = false
        session = MockSessionStore.retrieve(id=1)

        assert_equal session.domain, TEST_SHOPIFY_DOMAIN
        assert_equal session.token, TEST_SHOPIFY_TOKEN
      ensure
        ShopifyApp.configuration.per_user_tokens = false
      end
    end

    test "tests that session store can store shop session records" do
      assert false
    end
  end
end
