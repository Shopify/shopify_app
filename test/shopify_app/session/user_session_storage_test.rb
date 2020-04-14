# frozen_string_literal: true
require 'test_helper'

class UserMockSessionStore < ActiveRecord::Base
  include ShopifyApp::UserSessionStorage
end

module ShopifyApp
  class UserSessionStorageTest < ActiveSupport::TestCase
    TEST_SHOPIFY_USER_ID = 42
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_USER_TOKEN = "some-user-token-42"

    test ".retrieve returns user session by id" do
      UserMockSessionStore.stubs(:find_by).returns(MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN
      ))

      session = UserMockSessionStore.retrieve(shopify_user_id: TEST_SHOPIFY_USER_ID)

      assert_equal TEST_SHOPIFY_DOMAIN, session.domain
      assert_equal TEST_SHOPIFY_USER_TOKEN, session.token
    end

    test ".retrieve_by_shopify_user_id returns user session by shopify_user_id" do
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

      user_id = TEST_SHOPIFY_USER_ID
      session = UserMockSessionStore.retrieve_by_shopify_user_id(user_id)
      assert_equal expected_session.domain, session.domain
      assert_equal expected_session.token, session.token
      assert_equal expected_session.api_version, session.api_version
    end

    test ".store can store user session record" do
      mock_user_instance = MockUserInstance.new(shopify_user_id: 100)
      mock_user_instance.stubs(:save!).returns(true)

      UserMockSessionStore.stubs(:find_or_initialize_by).returns(mock_user_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:domain).returns(mock_user_instance.shopify_domain)
      mock_auth_hash.stubs(:token).returns("a-new-user_token!")

      associated_user = {
        id: 100,
      }

      saved_id = UserMockSessionStore.store(mock_auth_hash, user: associated_user)

      assert_equal "a-new-user_token!", mock_user_instance.shopify_token
      assert_equal mock_user_instance.id, saved_id
    end

    test '.retrieve returns nil for non-existent user' do
      user_id = 'non-existent-user'
      UserMockSessionStore.stubs(:find_by).with(id: user_id).returns(nil)

      refute UserMockSessionStore.retrieve(user_id)
    end

    test '.retrieve_by_user_id returns nil for non-existent user' do
      user_id = 'non-existent-user'
      UserMockSessionStore.stubs(:find_by).with(shopify_user_id: user_id).returns(nil)

      refute UserMockSessionStore.retrieve_by_shopify_user_id(user_id)
    end
  end
end
