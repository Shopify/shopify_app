# frozen_string_literal: true

require_relative "../../test_helper"

class ShopMockSessionStore < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorage
end

module ShopifyApp
  class ShopSessionStorageTest < ActiveSupport::TestCase
    TEST_SHOPIFY_DOMAIN = "example.myshopify.com"
    TEST_SHOPIFY_TOKEN = "1234567890qwertyuiop"

    test ".retrieve can retrieve shop session records by ID" do
      ShopMockSessionStore.stubs(:find_by).returns(MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
      ))

      session = ShopMockSessionStore.retrieve(1)
      assert_equal TEST_SHOPIFY_DOMAIN, session.shop
      assert_equal TEST_SHOPIFY_TOKEN, session.access_token
    end

    test ".retrieve_by_shopify_domain can retrieve shop session records by JWT" do
      instance = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
      )
      ShopMockSessionStore.stubs(:find_by).with(shopify_domain: TEST_SHOPIFY_DOMAIN).returns(instance)

      expected_session = ShopifyAPI::Auth::Session.new(
        shop: instance.shopify_domain,
        access_token: instance.shopify_token,
      )
      shopify_domain = TEST_SHOPIFY_DOMAIN

      session = ShopMockSessionStore.retrieve_by_shopify_domain(shopify_domain)
      assert_equal expected_session.shop, session.shop
      assert_equal expected_session.access_token, session.access_token
    end

    test ".destroy_by_shopify_domain destroys shop session records by JWT" do
      ShopMockSessionStore.expects(:destroy_by).with(shopify_domain: TEST_SHOPIFY_DOMAIN)

      ShopMockSessionStore.destroy_by_shopify_domain(TEST_SHOPIFY_DOMAIN)
    end

    test ".store can store shop session records" do
      mock_shop_instance = MockShopInstance.new(id: 12345)
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:shop).returns(mock_shop_instance.shopify_domain)
      mock_auth_hash.stubs(:access_token).returns("a-new-token!")
      mock_auth_hash.stubs(:scope).returns(ShopifyAPI::Auth::AuthScopes.new("read_products,write_orders"))
      saved_id = ShopMockSessionStore.store(mock_auth_hash)

      assert_equal "a-new-token!", mock_shop_instance.shopify_token
      assert_equal mock_shop_instance.id, saved_id
    end

    test ".retrieve returns nil for non-existent shop" do
      shop_id = "non-existent-id"
      ShopMockSessionStore.stubs(:find_by).with(id: shop_id).returns(nil)

      refute ShopMockSessionStore.retrieve(shop_id)
    end

    test ".retrieve_by_shopify_domain returns nil for non-existent shop" do
      shop_domain = "non-existent-id"

      ShopMockSessionStore.stubs(:find_by).with(shopify_domain: shop_domain).returns(nil)

      refute ShopMockSessionStore.retrieve_by_shopify_domain(shop_domain)
    end

    test ".store saves access_scopes when column exists" do
      mock_shop_instance = MockShopInstance.new(
        id: 12345,
        scopes: nil,
        available_attributes: [:id, :shopify_domain, :shopify_token, :access_scopes],
      )
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:shop).returns(TEST_SHOPIFY_DOMAIN)
      mock_auth_hash.stubs(:access_token).returns("a-new-token!")
      mock_auth_hash.stubs(:scope).returns(ShopifyAPI::Auth::AuthScopes.new("read_products,write_orders"))

      ShopMockSessionStore.store(mock_auth_hash)

      assert_equal "read_products,write_orders", mock_shop_instance.access_scopes
    end

    test ".store does not save access_scopes when column does not exist" do
      mock_shop_instance = MockShopInstance.new(
        id: 12345,
        scopes: "old_scopes",
        available_attributes: [:id, :shopify_domain, :shopify_token],
      )
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:shop).returns(TEST_SHOPIFY_DOMAIN)
      mock_auth_hash.stubs(:access_token).returns("a-new-token!")
      mock_auth_hash.stubs(:scope).returns(ShopifyAPI::Auth::AuthScopes.new("read_products,write_orders"))

      ShopMockSessionStore.store(mock_auth_hash)

      # access_scopes should remain unchanged since column doesn't exist
      assert_equal "old_scopes", mock_shop_instance.access_scopes
    end

    test ".store saves expires_at when column exists" do
      expiry_time = Time.now + 1.day
      mock_shop_instance = MockShopInstance.new(
        id: 12345,
        expires_at: nil,
        available_attributes: [:id, :shopify_domain, :shopify_token, :expires_at],
      )
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:shop).returns(TEST_SHOPIFY_DOMAIN)
      mock_auth_hash.stubs(:access_token).returns("a-new-token!")
      mock_auth_hash.stubs(:expires).returns(expiry_time)

      ShopMockSessionStore.store(mock_auth_hash)

      assert_equal expiry_time, mock_shop_instance.expires_at
    end

    test ".store does not save expires_at when column does not exist" do
      old_expiry = Time.now + 2.days
      mock_shop_instance = MockShopInstance.new(
        id: 12345,
        expires_at: old_expiry,
        available_attributes: [:id, :shopify_domain, :shopify_token],
      )
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:shop).returns(TEST_SHOPIFY_DOMAIN)
      mock_auth_hash.stubs(:access_token).returns("a-new-token!")
      mock_auth_hash.stubs(:expires).returns(Time.now + 1.day)

      ShopMockSessionStore.store(mock_auth_hash)

      # expires_at should remain unchanged since column doesn't exist
      assert_equal old_expiry, mock_shop_instance.expires_at
    end

    test ".store saves refresh_token when column exists" do
      mock_shop_instance = MockShopInstance.new(
        id: 12345,
        refresh_token: nil,
        available_attributes: [:id, :shopify_domain, :shopify_token, :refresh_token],
      )
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:shop).returns(TEST_SHOPIFY_DOMAIN)
      mock_auth_hash.stubs(:access_token).returns("a-new-token!")
      mock_auth_hash.stubs(:refresh_token).returns("new-refresh-token")

      ShopMockSessionStore.store(mock_auth_hash)

      assert_equal "new-refresh-token", mock_shop_instance.refresh_token
    end

    test ".store does not save refresh_token when column does not exist" do
      mock_shop_instance = MockShopInstance.new(
        id: 12345,
        refresh_token: "old-refresh-token",
        available_attributes: [:id, :shopify_domain, :shopify_token],
      )
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:shop).returns(TEST_SHOPIFY_DOMAIN)
      mock_auth_hash.stubs(:access_token).returns("a-new-token!")
      mock_auth_hash.stubs(:refresh_token).returns("new-refresh-token")

      ShopMockSessionStore.store(mock_auth_hash)

      # refresh_token should remain unchanged since column doesn't exist
      assert_equal "old-refresh-token", mock_shop_instance.refresh_token
    end

    test ".store saves refresh_token_expires_at when column exists" do
      refresh_expiry_time = Time.now + 7.days
      mock_shop_instance = MockShopInstance.new(
        id: 12345,
        refresh_token_expires_at: nil,
        available_attributes: [:id, :shopify_domain, :shopify_token, :refresh_token_expires_at],
      )
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:shop).returns(TEST_SHOPIFY_DOMAIN)
      mock_auth_hash.stubs(:access_token).returns("a-new-token!")
      mock_auth_hash.stubs(:refresh_token_expires).returns(refresh_expiry_time)

      ShopMockSessionStore.store(mock_auth_hash)

      assert_equal refresh_expiry_time, mock_shop_instance.refresh_token_expires_at
    end

    test ".store does not save refresh_token_expires_at when column does not exist" do
      old_refresh_expiry = Time.now + 14.days
      mock_shop_instance = MockShopInstance.new(
        id: 12345,
        refresh_token_expires_at: old_refresh_expiry,
        available_attributes: [:id, :shopify_domain, :shopify_token],
      )
      mock_shop_instance.stubs(:save!).returns(true)

      ShopMockSessionStore.stubs(:find_or_initialize_by).returns(mock_shop_instance)

      mock_auth_hash = mock
      mock_auth_hash.stubs(:shop).returns(TEST_SHOPIFY_DOMAIN)
      mock_auth_hash.stubs(:access_token).returns("a-new-token!")
      mock_auth_hash.stubs(:refresh_token_expires).returns(Time.now + 7.days)

      ShopMockSessionStore.store(mock_auth_hash)

      # refresh_token_expires_at should remain unchanged since column doesn't exist
      assert_equal old_refresh_expiry, mock_shop_instance.refresh_token_expires_at
    end

    test ".retrieve constructs session with all optional attributes when columns exist" do
      expiry_time = Time.now + 1.day
      refresh_expiry_time = Time.now + 7.days

      mock_shop_instance = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        scopes: "read_products,write_orders",
        expires_at: expiry_time,
        refresh_token: "refresh-token-value",
        refresh_token_expires_at: refresh_expiry_time,
        available_attributes: [
          :shopify_domain,
          :shopify_token,
          :access_scopes,
          :expires_at,
          :refresh_token,
          :refresh_token_expires_at,
        ],
      )

      ShopMockSessionStore.stubs(:find_by).with(id: 1).returns(mock_shop_instance)

      session = ShopMockSessionStore.retrieve(1)

      assert_equal TEST_SHOPIFY_DOMAIN, session.shop
      assert_equal TEST_SHOPIFY_TOKEN, session.access_token
      assert_equal "read_products,write_orders", session.scope.to_s
      assert_equal expiry_time, session.expires
      assert_equal "refresh-token-value", session.refresh_token
      assert_equal refresh_expiry_time, session.refresh_token_expires
    end

    test ".retrieve constructs session without optional attributes when columns do not exist" do
      mock_shop_instance = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        available_attributes: [:shopify_domain, :shopify_token],
        scopes: "old_scopes",
        expires_at:  Time.now + 2.days,
        refresh_token:  "old-refresh-token",
        refresh_token_expires_at: Time.now + 14.days,
      )

      ShopMockSessionStore.stubs(:find_by).with(id: 1).returns(mock_shop_instance)

      session = ShopMockSessionStore.retrieve(1)

      assert_equal TEST_SHOPIFY_DOMAIN, session.shop
      assert_equal TEST_SHOPIFY_TOKEN, session.access_token
      # Optional attributes should not be present
      assert_empty session.scope.to_a
      assert_nil session.expires
      assert_nil session.refresh_token
      assert_nil session.refresh_token_expires
    end

    test "#refresh_token_if_expired! does nothing when token is not expired" do
      shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        expires_at: 1.day.from_now,
        refresh_token: "refresh-token",
        refresh_token_expires_at: 30.days.from_now,
        available_attributes: [:shopify_domain, :shopify_token, :expires_at, :refresh_token, :refresh_token_expires_at],
      )

      ShopifyAPI::Auth::RefreshToken.expects(:refresh_access_token).never
      shop.expects(:update!).never

      shop.refresh_token_if_expired!

      # Token should remain unchanged
      assert_equal TEST_SHOPIFY_TOKEN, shop.shopify_token
    end

    test "#refresh_token_if_expired! refreshes when token is expired" do
      expired_time = 1.hour.ago
      new_expiry = 1.day.from_now
      new_refresh_token_expiry = 30.days.from_now

      shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: "old-token",
        expires_at: expired_time,
        refresh_token: "refresh-token",
        refresh_token_expires_at: 30.days.from_now,
        available_attributes: [:shopify_domain, :shopify_token, :expires_at, :refresh_token, :refresh_token_expires_at],
      )

      # Mock the refresh response
      new_session = mock
      new_session.stubs(:access_token).returns("new-token")
      new_session.stubs(:expires).returns(new_expiry)
      new_session.stubs(:refresh_token).returns("new-refresh-token")
      new_session.stubs(:refresh_token_expires).returns(new_refresh_token_expiry)

      ShopifyAPI::Auth::RefreshToken.expects(:refresh_access_token)
        .with(shop: TEST_SHOPIFY_DOMAIN, refresh_token: "refresh-token")
        .returns(new_session)

      shop.refresh_token_if_expired!

      # Verify the token was updated
      assert_equal "new-token", shop.shopify_token
      assert_equal new_expiry, shop.expires_at
      assert_equal "new-refresh-token", shop.refresh_token
      assert_equal new_refresh_token_expiry, shop.refresh_token_expires_at
    end

    test "#refresh_token_if_expired! raises error when refresh token is expired" do
      shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: "old-token",
        expires_at: 1.hour.ago,
        refresh_token: "refresh-token",
        refresh_token_expires_at: 1.hour.ago,
        available_attributes: [:shopify_domain, :shopify_token, :expires_at, :refresh_token, :refresh_token_expires_at],
      )

      ShopifyAPI::Auth::RefreshToken.expects(:refresh_access_token).never

      assert_raises(ShopifyApp::RefreshTokenExpiredError) do
        shop.refresh_token_if_expired!
      end
    end

    test "#refresh_token_if_expired! does nothing when refresh_token column doesn't exist" do
      shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        expires_at: 1.hour.ago,
        refresh_token_expires_at: 30.days.from_now,
        available_attributes: [:shopify_domain, :shopify_token, :expires_at, :refresh_token_expires_at],
      )

      ShopifyAPI::Auth::RefreshToken.expects(:refresh_access_token).never
      shop.expects(:update!).never

      shop.refresh_token_if_expired!

      assert_equal TEST_SHOPIFY_TOKEN, shop.shopify_token
    end

    test "#refresh_token_if_expired! does nothing when refresh_token is empty" do
      shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        expires_at: 1.hour.ago,
        refresh_token: "",
        refresh_token_expires_at: 30.days.from_now,
        available_attributes: [:shopify_domain, :shopify_token, :expires_at, :refresh_token, :refresh_token_expires_at],
      )

      ShopifyAPI::Auth::RefreshToken.expects(:refresh_access_token).never
      shop.expects(:update!).never

      shop.refresh_token_if_expired!

      assert_equal TEST_SHOPIFY_TOKEN, shop.shopify_token
    end

    test "#refresh_token_if_expired! does nothing when expires_at column doesn't exist" do
      shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        refresh_token: "refresh-token",
        refresh_token_expires_at: 30.days.from_now,
        available_attributes: [:shopify_domain, :shopify_token, :refresh_token, :refresh_token_expires_at],
      )

      ShopifyAPI::Auth::RefreshToken.expects(:refresh_access_token).never
      shop.expects(:update!).never

      shop.refresh_token_if_expired!

      assert_equal TEST_SHOPIFY_TOKEN, shop.shopify_token
    end

    test "#refresh_token_if_expired! does nothing when expires_at is nil" do
      shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        expires_at: nil,
        refresh_token: "refresh-token",
        refresh_token_expires_at: 30.days.from_now,
        available_attributes: [:shopify_domain, :shopify_token, :expires_at, :refresh_token, :refresh_token_expires_at],
      )

      ShopifyAPI::Auth::RefreshToken.expects(:refresh_access_token).never
      shop.expects(:update!).never

      shop.refresh_token_if_expired!

      assert_equal TEST_SHOPIFY_TOKEN, shop.shopify_token
    end

    test "#refresh_token_if_expired! does nothing when refresh_token_expires_at column doesn't exist" do
      shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        expires_at: 1.hour.ago,
        refresh_token: "refresh-token",
        available_attributes: [:shopify_domain, :shopify_token, :expires_at, :refresh_token],
      )

      ShopifyAPI::Auth::RefreshToken.expects(:refresh_access_token).never
      shop.expects(:update!).never

      shop.refresh_token_if_expired!

      assert_equal TEST_SHOPIFY_TOKEN, shop.shopify_token
    end

    test "#refresh_token_if_expired! does nothing when refresh_token_expires_at is nil" do
      shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        expires_at: 1.hour.ago,
        refresh_token: "refresh-token",
        refresh_token_expires_at: nil,
        available_attributes: [:shopify_domain, :shopify_token, :expires_at, :refresh_token, :refresh_token_expires_at],
      )

      ShopifyAPI::Auth::RefreshToken.expects(:refresh_access_token).never
      shop.expects(:update!).never

      shop.refresh_token_if_expired!

      assert_equal TEST_SHOPIFY_TOKEN, shop.shopify_token
    end

    test "#refresh_token_if_expired! handles race condition with double-check" do
      expired_time = 1.hour.ago
      refreshed_time = 1.day.from_now

      shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: "old-token",
        expires_at: expired_time,
        refresh_token: "refresh-token",
        refresh_token_expires_at: 30.days.from_now,
        available_attributes: [:shopify_domain, :shopify_token, :expires_at, :refresh_token, :refresh_token_expires_at],
      )

      # Simulate another process already refreshed the token
      shop.expects(:reload).once.with do
        shop.expires_at = refreshed_time
        shop.shopify_token = "already-refreshed-token"
        true
      end.returns(shop)
      ShopifyAPI::Auth::RefreshToken.expects(:refresh_access_token).never

      shop.refresh_token_if_expired!

      assert_equal "already-refreshed-token", shop.shopify_token
    end

    test "#with_shopify_session calls refresh_token_if_expired! by default" do
      shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: TEST_SHOPIFY_TOKEN,
        available_attributes: [:shopify_domain, :shopify_token],
      )

      shop.expects(:refresh_token_if_expired!).once

      block_executed = false
      shop.with_shopify_session do
        block_executed = true
      end

      assert block_executed, "Block should have been executed"
    end

    test "#with_shopify_session skips refresh when auto_refresh is false" do
      expired_time = 1.hour.ago

      shop = MockShopInstance.new(
        shopify_domain: TEST_SHOPIFY_DOMAIN,
        shopify_token: "old-token",
        expires_at: expired_time,
        refresh_token: "refresh-token",
        available_attributes: [:shopify_domain, :shopify_token, :expires_at, :refresh_token],
      )

      # Should NOT refresh even though token is expired
      shop.expects(:refresh_token_if_expired!).never
      ShopifyAPI::Auth::RefreshToken.expects(:refresh_access_token).never

      block_executed = false

      shop.with_shopify_session(auto_refresh: false) do
        block_executed = true
      end

      assert block_executed, "Block should have been executed"
    end
  end
end
