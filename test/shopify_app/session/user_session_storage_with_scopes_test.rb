# frozen_string_literal: true

require "test_helper"

class UserMockSessionStoreWithScopes < ActiveRecord::Base
  include ShopifyApp::UserSessionStorageWithScopes
end

module ShopifyApp
  class UserSessionStorageWithScopesTest < ActiveSupport::TestCase
    TEST_SHOPIFY_USER_ID = 42
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_USER_TOKEN = "some-user-token-42"
    TEST_MERCHANT_SCOPES = "read_orders, write_products"

    test ".retrieve returns user session by id" do
      UserMockSessionStoreWithScopes.stubs(:find_by).returns(MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
        scopes: TEST_MERCHANT_SCOPES,
      ))

      session = UserMockSessionStoreWithScopes.retrieve(shopify_user_id: TEST_SHOPIFY_USER_ID)

      assert_equal TEST_SHOPIFY_DOMAIN, session.shop
      assert_equal TEST_SHOPIFY_USER_TOKEN, session.access_token
      assert_equal ShopifyAPI::Auth::AuthScopes.new(TEST_MERCHANT_SCOPES), session.scope
    end

    test ".retrieve_by_shopify_user_id returns user session by shopify_user_id" do
      instance = MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
        api_version: ShopifyApp.configuration.api_version,
        scopes: TEST_MERCHANT_SCOPES,
      )
      UserMockSessionStoreWithScopes.stubs(:find_by).with(shopify_user_id: TEST_SHOPIFY_USER_ID).returns(instance)

      expected_session = ShopifyAPI::Auth::Session.new(
        shop: instance.shopify_domain,
        access_token: instance.shopify_token,
        scope: TEST_MERCHANT_SCOPES,
      )

      user_id = TEST_SHOPIFY_USER_ID
      session = UserMockSessionStoreWithScopes.retrieve_by_shopify_user_id(user_id)
      assert_equal expected_session.shop, session.shop
      assert_equal expected_session.access_token, session.access_token
      assert_equal expected_session.scope, session.scope
    end

    test ".store can store user session record" do
      mock_user_instance = MockUserInstance.new(shopify_user_id: 100)
      mock_user_instance.stubs(:save!).returns(true)

      UserMockSessionStoreWithScopes.stubs(:find_or_initialize_by).returns(mock_user_instance)

      saved_id = UserMockSessionStoreWithScopes.store(
        mock_session(
          shop: mock_user_instance.shopify_domain,
          scope: TEST_MERCHANT_SCOPES,
        ),
        mock_associated_user,
      )

      assert_equal "a-new-user_token!", mock_user_instance.shopify_token
      assert_equal mock_user_instance.id, saved_id
    end

    test ".retrieve returns nil for non-existent user" do
      user_id = "non-existent-user"
      UserMockSessionStoreWithScopes.stubs(:find_by).with(id: user_id).returns(nil)

      refute UserMockSessionStoreWithScopes.retrieve(user_id)
    end

    test ".retrieve_by_user_id returns nil for non-existent user" do
      user_id = "non-existent-user"
      UserMockSessionStoreWithScopes.stubs(:find_by).with(shopify_user_id: user_id).returns(nil)

      refute UserMockSessionStoreWithScopes.retrieve_by_shopify_user_id(user_id)
    end

    test ".retrieve throws NotImplementedError when access_scopes getter is not implemented" do
      mock_user = MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
      )
      mock_user.stubs(:access_scopes).raises(NotImplementedError)
      UserMockSessionStoreWithScopes.stubs(:find_by).returns(mock_user)

      assert_raises NotImplementedError do
        UserMockSessionStoreWithScopes.retrieve(1)
      end
    end

    private

    def mock_associated_user
      ShopifyAPI::Auth::AssociatedUser.new(
        id: 100,
        first_name: "John",
        last_name: "Doe",
        email: "johndoe@email.com",
        email_verified: true,
        account_owner: false,
        locale: "en",
        collaborator: true,
      )
    end
  end
end
