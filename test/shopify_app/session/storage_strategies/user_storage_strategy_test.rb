require 'test_helper'


class MockSessionStore < ActiveRecord::Base
  include ShopifyApp::SessionStorage
end


module ShopifyApp
  class UserStorageStrategyTest < ActiveSupport::TestCase
    TEST_SHOPIFY_USER_ID = 42
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_USER_TOKEN = "some-user-token-42"

    test "tests that session store can retrieve user session records" do
      MockSessionStore.stubs(:find_by).with(shopify_user_id: TEST_SHOPIFY_USER_ID).returns(MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
      ))

      begin
        MockSessionStore.storage_strategy = ShopifyApp::SessionStorage::UserStorageStrategy.new(MockSessionStore)
        session = MockSessionStore.retrieve(TEST_SHOPIFY_USER_ID)

        assert_equal TEST_SHOPIFY_DOMAIN, session.domain
        assert_equal TEST_SHOPIFY_USER_TOKEN, session.token
      ensure
        MockSessionStore.storage_strategy = nil
      end
    end

    test "tests that session store can store user session records" do
      mock_user_instance = MockUserInstance.new(shopify_user_id:100)
      mock_user_instance.stubs(:save!).returns(true)

      mock_user_class = Object.new
      MockSessionStore.
        stubs(:find_or_initialize_by).
        with(shopify_user_id: mock_user_instance.shopify_user_id).
        returns(mock_user_instance)

      begin
        MockSessionStore.storage_strategy = ShopifyApp::SessionStorage::UserStorageStrategy.new(MockSessionStore)
        mock_auth_hash = mock()
        mock_auth_hash.stubs(:domain).returns(mock_user_instance.shopify_domain)
        mock_auth_hash.stubs(:token).returns("a-new-user_token!")

        associated_user = {
          id: 100,
        }

        saved_id = MockSessionStore.store(mock_auth_hash, user: associated_user)

        assert_equal "a-new-user_token!", mock_user_instance.shopify_token
        assert_equal mock_user_instance.id, saved_id

      ensure
        MockSessionStore.storage_strategy = nil
      end
    end
  end
end
