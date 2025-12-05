# frozen_string_literal: true

require_relative "../../test_helper"

class UserMockSessionStore < ActiveRecord::Base
  include ShopifyApp::UserSessionStorage
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
      ))

      session = UserMockSessionStore.retrieve(shopify_user_id: TEST_SHOPIFY_USER_ID)

      assert_equal TEST_SHOPIFY_DOMAIN, session.shop
      assert_equal TEST_SHOPIFY_USER_TOKEN, session.access_token
    end

    test ".retrieve_by_shopify_user_id returns user session by shopify_user_id" do
      instance = MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
        api_version: ShopifyApp.configuration.api_version,
      )
      UserMockSessionStore.stubs(:find_by).with(shopify_user_id: TEST_SHOPIFY_USER_ID).returns(instance)

      expected_session = ShopifyAPI::Auth::Session.new(
        shop: instance.shopify_domain,
        access_token: instance.shopify_token,
      )

      user_id = TEST_SHOPIFY_USER_ID
      session = UserMockSessionStore.retrieve_by_shopify_user_id(user_id)
      assert_equal expected_session.shop, session.shop
      assert_equal expected_session.access_token, session.access_token
    end

    test ".destroy_by_shopify_user_id destroys user session by shopify_user_id" do
      UserMockSessionStore.expects(:destroy_by).with(shopify_user_id: TEST_SHOPIFY_USER_ID)

      UserMockSessionStore.destroy_by_shopify_user_id(TEST_SHOPIFY_USER_ID)
    end

    test ".store can store user session record" do
      mock_user_instance = MockUserInstance.new(shopify_user_id: 100)
      mock_user_instance.stubs(:save!).returns(true)

      UserMockSessionStore.stubs(:find_or_initialize_by).returns(mock_user_instance)

      saved_id = UserMockSessionStore.store(
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
      UserMockSessionStore.stubs(:find_by).with(id: user_id).returns(nil)

      refute UserMockSessionStore.retrieve(user_id)
    end

    test ".retrieve_by_user_id returns nil for non-existent user" do
      user_id = "non-existent-user"
      UserMockSessionStore.stubs(:find_by).with(shopify_user_id: user_id).returns(nil)

      refute UserMockSessionStore.retrieve_by_shopify_user_id(user_id)
    end

    test ".store saves access_scopes when column exists" do
      mock_user_instance = MockUserInstance.new(
        id: 12345,
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        scopes: nil,
        available_attributes: [:id, :shopify_user_id, :shopify_domain, :shopify_token, :access_scopes],
      )
      mock_user_instance.stubs(:save!).returns(true)

      UserMockSessionStore.stubs(:find_or_initialize_by).returns(mock_user_instance)

      UserMockSessionStore.store(
        mock_session(shop: TEST_SHOPIFY_DOMAIN, scope: "read_products,write_orders"),
        mock_associated_user,
      )

      assert_equal "read_products,write_orders", mock_user_instance.access_scopes
    end

    test ".store does not save access_scopes when column does not exist" do
      mock_user_instance = MockUserInstance.new(
        id: 12345,
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        scopes: "old_scopes",
        available_attributes: [:id, :shopify_user_id, :shopify_domain, :shopify_token],
      )
      mock_user_instance.stubs(:save!).returns(true)

      UserMockSessionStore.stubs(:find_or_initialize_by).returns(mock_user_instance)

      UserMockSessionStore.store(
        mock_session(shop: TEST_SHOPIFY_DOMAIN, scope: "read_products,write_orders"),
        mock_associated_user,
      )

      # access_scopes should remain unchanged since column doesn't exist
      assert_equal "old_scopes", mock_user_instance.access_scopes
    end

    test ".store saves expires_at when column exists" do
      expiry_time = Time.now + 1.day
      mock_user_instance = MockUserInstance.new(
        id: 12345,
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        expires_at: nil,
        available_attributes: [:id, :shopify_user_id, :shopify_domain, :shopify_token, :expires_at],
      )
      mock_user_instance.stubs(:save!).returns(true)

      UserMockSessionStore.stubs(:find_or_initialize_by).returns(mock_user_instance)

      mock_auth_session = mock_session(shop: TEST_SHOPIFY_DOMAIN, expires: expiry_time)

      UserMockSessionStore.store(mock_auth_session, mock_associated_user)

      assert_equal expiry_time, mock_user_instance.expires_at
    end

    test ".store does not save expires_at when column does not exist" do
      old_expiry = Time.now + 2.days
      mock_user_instance = MockUserInstance.new(
        id: 12345,
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        expires_at: old_expiry,
        available_attributes: [:id, :shopify_user_id, :shopify_domain, :shopify_token],
      )
      mock_user_instance.stubs(:save!).returns(true)

      UserMockSessionStore.stubs(:find_or_initialize_by).returns(mock_user_instance)

      UserMockSessionStore.store(
        mock_session(shop: TEST_SHOPIFY_DOMAIN, expires: Time.now + 1.day),
        mock_associated_user,
      )

      # expires_at should remain unchanged since column doesn't exist
      assert_equal old_expiry, mock_user_instance.expires_at
    end

    test ".retrieve constructs session with all optional attributes when columns exist" do
      expiry_time = Time.now + 1.day

      mock_user_instance = MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
        scopes: "read_products,write_orders",
        expires_at: expiry_time,
        available_attributes: [:shopify_user_id, :shopify_domain, :shopify_token, :access_scopes, :expires_at],
      )

      UserMockSessionStore.stubs(:find_by).with(id: 1).returns(mock_user_instance)

      session = UserMockSessionStore.retrieve(1)

      assert_equal TEST_SHOPIFY_DOMAIN, session.shop
      assert_equal TEST_SHOPIFY_USER_TOKEN, session.access_token
      assert_equal "read_products,write_orders", session.scope.to_s
      assert_equal expiry_time, session.expires
    end

    test ".retrieve constructs session without optional attributes when columns do not exist" do
      mock_user_instance = MockUserInstance.new(
        shopify_user_id: TEST_SHOPIFY_USER_ID,
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_USER_TOKEN,
        available_attributes: [:shopify_user_id, :shopify_domain, :shopify_token],
        scopes: "old_scopes",
        expires_at: Time.now + 2.days,
      )

      UserMockSessionStore.stubs(:find_by).with(id: 1).returns(mock_user_instance)

      session = UserMockSessionStore.retrieve(1)

      assert_equal TEST_SHOPIFY_DOMAIN, session.shop
      assert_equal TEST_SHOPIFY_USER_TOKEN, session.access_token
      # Optional attributes should not be present
      assert_empty session.scope.to_a
      assert_nil session.expires
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

    def mock_session(shop:, scope: nil, expires: nil)
      mock_auth_hash = mock
      mock_auth_hash.stubs(:shop).returns(shop)
      mock_auth_hash.stubs(:access_token).returns("a-new-user_token!")
      mock_auth_hash.stubs(:scope).returns(scope.is_a?(String) ? ShopifyAPI::Auth::AuthScopes.new(scope) : scope)
      mock_auth_hash.stubs(:expires).returns(expires)
      mock_auth_hash
    end
  end
end
