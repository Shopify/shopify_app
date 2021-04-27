# frozen_string_literal: true
require 'test_helper'

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

    test '.user_storage accepts a String as argument' do
      SessionRepository.user_storage = 'ShopifyApp::InMemoryUserSessionStore'
      assert_kind_of InMemoryUserSessionStore.class, SessionRepository.user_storage
    end

    test ".shop_storage= does not raise ArgumentError if input is nil" do
      assert_nothing_raised { SessionRepository.shop_storage = nil }
    end

    test ".shop_storage= clears storage setting if input is nil" do
      SessionRepository.shop_storage = InMemoryShopSessionStore
      assert_kind_of InMemoryShopSessionStore.class, SessionRepository.user_storage

      SessionRepository.shop_storage = nil
      assert_raises(SessionRepository::ConfigurationError) { SessionRepository.shop_storage }
    end

    test '.shop_storage accepts a String as argument' do
      SessionRepository.shop_storage = 'ShopifyApp::InMemoryShopSessionStore'
      assert_kind_of InMemoryShopSessionStore.class, SessionRepository.shop_storage
    end

    test '.retrieve_user_session_by_shopify_user_id retrieves a user session by JWT' do
      SessionRepository.user_storage = InMemoryUserSessionStore

      InMemoryUserSessionStore.expects(:retrieve_by_shopify_user_id).with(mock_shopify_user_id)

      SessionRepository.retrieve_user_session_by_shopify_user_id(mock_shopify_user_id)
    end

    test '.retrieve_shop_session_by_shopify_domain retrieves a shop session by JWT' do
      SessionRepository.shop_storage = InMemoryShopSessionStore

      InMemoryShopSessionStore.expects(:retrieve_by_shopify_domain).with(mock_shopify_domain)

      SessionRepository.retrieve_shop_session_by_shopify_domain(mock_shopify_domain)
    end

    test '.retrieve_user_session retrieves a user session' do
      SessionRepository.user_storage = InMemoryUserSessionStore

      InMemoryUserSessionStore.expects(:retrieve).with(mock_shopify_user_id)

      SessionRepository.retrieve_user_session(mock_shopify_user_id)
    end

    test '.retrieve_shop_session retrieves a shop session' do
      SessionRepository.shop_storage = InMemoryShopSessionStore

      mock_shop_id = 'abra-shop'
      InMemoryShopSessionStore.expects(:retrieve).with(mock_shop_id)

      SessionRepository.retrieve_shop_session(mock_shop_id)
    end

    test '.store_shop_session stores a shop session' do
      SessionRepository.shop_storage = InMemoryShopSessionStore

      session = mock_shopify_session
      InMemoryShopSessionStore.expects(:store).with(session)

      SessionRepository.store_shop_session(session)
    end

    test '.store_user_session stores a user session' do
      SessionRepository.user_storage = InMemoryUserSessionStore

      session = mock_shopify_session
      user = { 'id' => 'abra' }
      InMemoryUserSessionStore.expects(:store).with(session, user)

      SessionRepository.store_user_session(session, user)
    end

    private

    def mock_shopify_domain
      'shop.myshopify.com'
    end

    def mock_shopify_user_id
      'abra'
    end

    def mock_shopify_session
      ShopifyAPI::Session.new(
        domain: mock_shopify_domain,
        token: 'abracadabra',
        api_version: :unstable,
        access_scopes: 'read_products'
      )
    end
  end
end
