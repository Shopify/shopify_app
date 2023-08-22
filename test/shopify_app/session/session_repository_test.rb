# frozen_string_literal: true

require "test_helper"
require_relative "../../../lib/generators/shopify_app/shop_model/templates/shop.rb"
require_relative "../../../lib/generators/shopify_app/user_model/templates/user.rb"

module ShopifyApp
  class SessionRepositoryTest < ActiveSupport::TestCase
    teardown do
      SessionRepository.shop_storage = nil
      SessionRepository.user_storage = nil
    end

    test ".user_storage= does not raise ArgumentError if input is nil" do
      assert_nothing_raised { SessionRepository.user_storage = nil }
    end

    test ".user_storage= clears storage setting if input is nil" do
      SessionRepository.user_storage = InMemoryUserSessionStore
      assert_kind_of InMemoryUserSessionStore.class, SessionRepository.user_storage

      SessionRepository.user_storage = nil
      assert_kind_of NullUserSessionStore.class, SessionRepository.user_storage
    end

    test ".user_storage accepts a String as argument" do
      SessionRepository.user_storage = "ShopifyApp::InMemoryUserSessionStore"
      assert_kind_of InMemoryUserSessionStore.class, SessionRepository.user_storage
    end

    test ".shop_storage= does not raise ArgumentError if input is nil" do
      assert_nothing_raised { SessionRepository.shop_storage = nil }
    end

    test ".shop_storage= clears storage setting if input is nil" do
      SessionRepository.shop_storage = InMemoryShopSessionStore
      assert_kind_of InMemoryShopSessionStore.class, SessionRepository.user_storage

      SessionRepository.shop_storage = nil
      assert_raises(::ShopifyApp::ConfigurationError) { SessionRepository.shop_storage }
    end

    test ".shop_storage accepts a String as argument" do
      SessionRepository.shop_storage = "ShopifyApp::InMemoryShopSessionStore"
      assert_kind_of InMemoryShopSessionStore.class, SessionRepository.shop_storage
    end

    test ".retrieve_user_session_by_shopify_user_id retrieves a user session by JWT" do
      SessionRepository.user_storage = InMemoryUserSessionStore

      InMemoryUserSessionStore.expects(:retrieve_by_shopify_user_id).with(mock_shopify_user_id)

      SessionRepository.retrieve_user_session_by_shopify_user_id(mock_shopify_user_id)
    end

    test ".retrieve_shop_session_by_shopify_domain retrieves a shop session by JWT" do
      SessionRepository.shop_storage = InMemoryShopSessionStore

      InMemoryShopSessionStore.expects(:retrieve_by_shopify_domain).with(mock_shopify_domain)

      SessionRepository.retrieve_shop_session_by_shopify_domain(mock_shopify_domain)
    end

    test ".retrieve_user_session retrieves a user session" do
      SessionRepository.user_storage = InMemoryUserSessionStore

      InMemoryUserSessionStore.expects(:retrieve).with(mock_shopify_user_id)

      SessionRepository.retrieve_user_session(mock_shopify_user_id)
    end

    test ".retrieve_shop_session retrieves a shop session" do
      SessionRepository.shop_storage = InMemoryShopSessionStore

      mock_shop_id = "abra-shop"
      InMemoryShopSessionStore.expects(:retrieve).with(mock_shop_id)

      SessionRepository.retrieve_shop_session(mock_shop_id)
    end

    test ".store_shop_session stores a shop session" do
      SessionRepository.shop_storage = InMemoryShopSessionStore

      session = mock_shopify_session
      InMemoryShopSessionStore.expects(:store).with(session)

      SessionRepository.store_shop_session(session)
    end

    test ".store_user_session stores a user session" do
      SessionRepository.user_storage = InMemoryUserSessionStore

      session = mock_shopify_session
      user = { "id" => "abra" }
      InMemoryUserSessionStore.expects(:store).with(session, user)

      SessionRepository.store_user_session(session, user)
    end

    test ".store_session stores a user session" do
      SessionRepository.user_storage = InMemoryUserSessionStore

      session = mock_shopify_session
      session.stubs(:online?).returns(true)

      user = mock_associated_user
      session.stubs(:associated_user).returns(user)

      InMemoryUserSessionStore.expects(:store).with(session, user)

      SessionRepository.store_session(session)
    end

    test ".store_session stores a shop session" do
      SessionRepository.shop_storage = InMemoryShopSessionStore

      session = mock_shopify_session

      InMemoryShopSessionStore.expects(:store).with(session)

      SessionRepository.store_session(session)
    end

    test ".load_session loads a user session" do
      SessionRepository.user_storage = InMemoryShopSessionStore

      mock_session_id = "test_shop.myshopify.com_1234"
      InMemoryShopSessionStore.expects(:retrieve_by_shopify_user_id).with("1234")

      SessionRepository.load_session(mock_session_id)
    end

    test ".load_session loads a shop session" do
      SessionRepository.shop_storage = InMemoryShopSessionStore

      mock_session_id = "offline_abra-shop"
      InMemoryShopSessionStore.expects(:retrieve_by_shopify_domain).with("abra-shop")

      SessionRepository.load_session(mock_session_id)
    end

    test(".delete_session destroys a shop record") do
      shop = MockShopInstance.new(shopify_domain: "shop", shopify_token: "token")

      Shop.expects(:find_by).with(shopify_domain: "shop").returns(shop)
      shop.expects(:destroy)

      SessionRepository.delete_session("offline_shop")
    end

    test(".delete_session destroys a user record") do
      user = MockUserInstance.new(shopify_domain: "shop", shopify_token: "token")

      User.expects(:find_by).with(shopify_user_id: "1234").returns(user)
      user.expects(:destroy)

      SessionRepository.delete_session("shop_1234")
    end

    private

    def mock_shopify_domain
      "shop.myshopify.com"
    end

    def mock_shopify_user_id
      "abra"
    end

    def mock_shopify_session
      ShopifyAPI::Auth::Session.new(
        shop: mock_shopify_domain,
        access_token: "abracadabra",
        scope: "read_products",
      )
    end

    def mock_associated_user
      ShopifyAPI::Auth::AssociatedUser.new(
        id: 1234,
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
