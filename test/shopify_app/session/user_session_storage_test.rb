# frozen_string_literal: true
require 'test_helper'

class UserMockSessionStore < ActiveRecord::Base
  include ShopifyApp::UserSessionStorage

  def access_scopes=(shop, scopes)
    shop.access_scopes = scopes
  end

  def access_scopes(shop)
    shop.access_scopes
  end
end

module ShopifyApp
  class UserSessionStorageTest < ActiveSupport::TestCase
    TEST_SHOPIFY_USER_ID = 42
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_USER_TOKEN = "some-user-token-42"
    TEST_MERCHANT_SCOPES = "read_orders, write_products"

    test ".retrieve returns user session by id" do
      UserMockSessionStore.stubs(:find_by).returns(MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
        scopes: TEST_MERCHANT_SCOPES
      ))

      session = UserMockSessionStore.retrieve(shopify_user_id: TEST_SHOPIFY_USER_ID)

      assert_equal TEST_SHOPIFY_DOMAIN, session.domain
      assert_equal TEST_SHOPIFY_USER_TOKEN, session.token
      assert_equal TEST_MERCHANT_SCOPES, session.extra[:scopes]
    end

    test ".retrieve_by_shopify_user_id returns user session by shopify_user_id" do
      instance = MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
        api_version: '2020-01',
        scopes: TEST_MERCHANT_SCOPES
      )
      UserMockSessionStore.stubs(:find_by).with(shopify_user_id: TEST_SHOPIFY_USER_ID).returns(instance)

      expected_session = ShopifyAPI::Session.new(
        domain: instance.shopify_domain,
        token: instance.shopify_token,
        api_version: instance.api_version,
        extra: { scopes: TEST_MERCHANT_SCOPES }
      )

      user_id = TEST_SHOPIFY_USER_ID
      session = UserMockSessionStore.retrieve_by_shopify_user_id(user_id)
      assert_equal expected_session.domain, session.domain
      assert_equal expected_session.token, session.token
      assert_equal expected_session.api_version, session.api_version
      assert_equal expected_session.extra, session.extra
    end

    test ".store can store user session record" do
      mock_user_instance = MockUserInstance.new(shopify_user_id: 100)
      mock_user_instance.stubs(:save!).returns(true)

      UserMockSessionStore.stubs(:find_or_initialize_by).returns(mock_user_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:domain).returns(mock_user_instance.shopify_domain)
      mock_auth_hash.stubs(:token).returns("a-new-user_token!")
      mock_auth_hash.stubs(:extra).returns({ scopes: TEST_MERCHANT_SCOPES })

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

    test '.retrieve_scopes_by_shopify_domain returns access scopes for shop record' do
      UserMockSessionStore.stubs(:find_by).returns(MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
        scopes: TEST_MERCHANT_SCOPES
      ))

      user_scopes = UserMockSessionStore.retrieve_access_scopes_by_shopify_user_id(TEST_SHOPIFY_USER_ID)

      assert_equal TEST_MERCHANT_SCOPES, user_scopes
    end

    test '.retrieve returns user session with nil scopes if access_scopes attribute throws NoMethodError' do
      mock_user = MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
        )
      mock_user.stubs(:access_scopes).raises(NoMethodError)
      UserMockSessionStore.stubs(:find_by).returns(mock_user)

      session = UserMockSessionStore.retrieve(1)
      assert_equal TEST_SHOPIFY_DOMAIN, session.domain
      assert_equal TEST_SHOPIFY_USER_TOKEN, session.token
      assert_nil session.extra[:scopes]
    end

    test '.retrieve returns user session with nil scopes if access_scopes attribute throws NotImplementedError' do
      mock_user = MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
      )
      mock_user.stubs(:access_scopes).raises(NotImplementedError)
      UserMockSessionStore.stubs(:find_by).returns(mock_user)

      session = UserMockSessionStore.retrieve(1)
      assert_equal TEST_SHOPIFY_DOMAIN, session.domain
      assert_equal TEST_SHOPIFY_USER_TOKEN, session.token
      assert_nil session.extra[:scopes]
    end
  end
end
