require 'test_helper'

class UserMockSessionStore < ActiveRecord::Base
  include ShopifyApp::UserSessionStorage
end

module ShopifyApp
  class UserSessionStorageTest < ActiveSupport::TestCase
    TEST_SHOPIFY_USER_ID = 42
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_USER_TOKEN = "some-user-token-42"

    test "tests that session store can retrieve user session records by ID" do
      UserMockSessionStore.stubs(:find_by).returns(MockUserInstance.new(
        shopify_user_id:TEST_SHOPIFY_USER_ID,
        shopify_domain:TEST_SHOPIFY_DOMAIN,
        shopify_token:TEST_SHOPIFY_USER_TOKEN
      ))

      session = UserMockSessionStore.retrieve(shopify_user_id:TEST_SHOPIFY_USER_ID)

      assert_equal TEST_SHOPIFY_DOMAIN, session.domain
      assert_equal TEST_SHOPIFY_USER_TOKEN, session.token
    end

    test "tests that session store can retrieve user session records by JWT" do
      instance = MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
        api_version: '2020-01',
      )
      UserMockSessionStore.stubs(:find_by).with(shopify_user_id: TEST_SHOPIFY_USER_ID).returns(instance)

      expected_session = ShopifyAPI::Session.new(
        domain: instance.shopify_domain,
        token: instance.shopify_token,
        api_version: instance.api_version,
      )

      payload = { 'sub' => TEST_SHOPIFY_USER_ID }
      session = UserMockSessionStore.retrieve_by_jwt(payload)
      assert_equal expected_session.domain, session.domain
      assert_equal expected_session.token, session.token
      assert_equal expected_session.api_version, session.api_version
    end

    test "tests that session store can store user session records" do
      mock_user_instance = MockUserInstance.new(shopify_user_id:100)
      mock_user_instance.stubs(:save!).returns(true)

      UserMockSessionStore.stubs(:find_or_initialize_by).returns(mock_user_instance)

      mock_auth_hash = mock()
      mock_auth_hash.stubs(:domain).returns(mock_user_instance.shopify_domain)
      mock_auth_hash.stubs(:token).returns("a-new-user_token!")

      associated_user = {
        id: 100,
      }

      saved_id = UserMockSessionStore.store(mock_auth_hash, user: associated_user)

      assert_equal "a-new-user_token!", mock_user_instance.shopify_token
      assert_equal mock_user_instance.id, saved_id
    end
  end
end
