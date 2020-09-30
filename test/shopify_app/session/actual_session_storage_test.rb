# frozen_string_literal: true
require 'test_helper'

class ActualSessionMockSessionStore < ActiveRecord::Base
  include ShopifyApp::ActualSessionStorage
end

module ShopifyApp
  class ActualSessionStorageTest < ActiveSupport::TestCase
    TEST_SHOPIFY_SESSION_ID = 42
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_USER_TOKEN = "some-user-token-42"
    TEST_EXPIRES_AT = Time.now

    test ".retrieve returns actual session by id" do
      ActualSessionMockSessionStore.stubs(:find_by).returns(MockActualSessionInstance.new(
        shopify_session_id: TEST_SHOPIFY_SESSION_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN
      ))

      session = ActualSessionMockSessionStore.retrieve(shopify_session_id: TEST_SHOPIFY_SESSION_ID)
      assert_equal TEST_SHOPIFY_DOMAIN, session.domain
      assert_equal TEST_SHOPIFY_USER_TOKEN, session.token
    end

    test ".retrieve_by_shopify_session_id returns user session by shopify_session_id" do
      instance = MockActualSessionInstance.new(
        shopify_session_id: TEST_SHOPIFY_SESSION_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
        api_version: '2020-01',
      )
      ActualSessionMockSessionStore.stubs(:find_by).with(shopify_session_id: TEST_SHOPIFY_SESSION_ID).returns(instance)

      expected_session = ShopifyAPI::Session.new(
        domain: instance.shopify_domain,
        token: instance.shopify_token,
        api_version: instance.api_version,
      )

      shopify_session_id = TEST_SHOPIFY_SESSION_ID
      session = ActualSessionMockSessionStore.retrieve_by_shopify_session_id(shopify_session_id)
      assert_equal expected_session.domain, session.domain
      assert_equal expected_session.token, session.token
      assert_equal expected_session.api_version, session.api_version
    end

    test ".store can store actual session record" do
      mock_session_instance = MockActualSessionInstance.new(shopify_session_id: 100)
      mock_session_instance.stubs(:save!).returns(true)

      ActualSessionMockSessionStore.stubs(:find_or_initialize_by).returns(mock_session_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:domain).returns(mock_session_instance.shopify_domain)
      mock_auth_hash.stubs(:token).returns("a-new-user_token!")

      associated_user = {
        id: 100,
      }
      saved_id = ActualSessionMockSessionStore.store(
        mock_auth_hash,
        TEST_SHOPIFY_SESSION_ID,
        associated_user,
        TEST_EXPIRES_AT
      )

      assert_equal "a-new-user_token!", mock_session_instance.shopify_token
      assert_equal mock_session_instance.id, saved_id
    end

    test '.retrieve returns nil for non-existent session' do
      shopify_session_id = 'non-existent-session'
      ActualSessionMockSessionStore.stubs(:find_by).with(id: shopify_session_id).returns(nil)

      refute ActualSessionMockSessionStore.retrieve(shopify_session_id)
    end

    test '.retrieve_by_session_id returns nil for non-existent session' do
      shopify_session_id = 'non-existent-session'
      ActualSessionMockSessionStore.stubs(:find_by).with(shopify_session_id: shopify_session_id).returns(nil)

      refute ActualSessionMockSessionStore.retrieve_by_shopify_session_id(shopify_session_id)
    end
  end
end
