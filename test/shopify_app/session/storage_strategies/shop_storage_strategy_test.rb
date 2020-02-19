require 'test_helper'

module ShopifyApp
  class ShopStorageStrategyTest < ActiveSupport::TestCase
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_TOKEN = "1234567890qwertyuiop"

    test "tests that session store can retrieve shop session records" do
      MockSessionStore.stubs(:find_by).with(id: 1).returns(MockShopInstance.new(
        shopify_domain:TEST_SHOPIFY_DOMAIN,
        shopify_token:TEST_SHOPIFY_TOKEN
      ))

      begin
        MockSessionStore.storage_strategy = ShopifyApp::SessionStorage::ShopStorageStrategy.new(MockSessionStore)
        session = MockSessionStore.retrieve(id=1)
        assert_equal TEST_SHOPIFY_DOMAIN, session.domain
        assert_equal TEST_SHOPIFY_TOKEN, session.token
      ensure
        MockSessionStore.storage_strategy = nil
      end
    end

    test "tests that session store can store shop session records" do
      mock_shop_instance = MockShopInstance.new(id:12345)
      mock_shop_instance.stubs(:save!).returns(true)

      MockSessionStore.
        stubs(:find_or_initialize_by).
        with(shopify_domain: mock_shop_instance.shopify_domain).
        returns(mock_shop_instance)

      begin
        MockSessionStore.storage_strategy = ShopifyApp::SessionStorage::ShopStorageStrategy.new(MockSessionStore)
        mock_auth_hash = mock()
        mock_auth_hash.stubs(:domain).returns(mock_shop_instance.shopify_domain)
        mock_auth_hash.stubs(:token).returns("a-new-token!")
        saved_id = MockSessionStore.store(mock_auth_hash)

        assert_equal "a-new-token!", mock_shop_instance.shopify_token
        assert_equal mock_shop_instance.id, saved_id
      ensure
        MockSessionStore.storage_strategy = nil
      end
    end

    test "#retrieve_by_domain retrieves shop session records by domain" do
      session_instance = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        api_version: '2020-01',
      )

      expected_session = ShopifyAPI::Session.new(
        domain: session_instance.shopify_domain,
        token: session_instance.shopify_token,
        api_version: session_instance.api_version,
      )

      MockSessionStore.stubs(:find_by).with(shopify_domain: session_instance.shopify_domain).returns(session_instance)

      begin
        ShopifyApp.configuration.per_user_tokens = false
        session = MockSessionStore.retrieve_by_domain(TEST_SHOPIFY_DOMAIN)
        assert_equal expected_session.domain, session.domain
        assert_equal expected_session.token, session.token
        assert_equal expected_session.api_version, session.api_version
      ensure
        ShopifyApp.configuration.per_user_tokens = false
      end
    end
  end
end
