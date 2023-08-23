# frozen_string_literal: true

require "test_helper"

module ShopifyApp
  class InMemoryUserSessionStoreTest < ActiveSupport::TestCase
    teardown do
      InMemoryUserSessionStore.clear
    end

    test "retrieving a session by JWT" do
      InMemoryUserSessionStore.repo["abra"] = "something"

      user_id = "abra"
      assert_equal "something", InMemoryUserSessionStore.retrieve_by_shopify_user_id(user_id)
    end

    test "stores a user session by id" do
      user_id = 123456
      user = ShopifyAPI::Auth::AssociatedUser.new(
        id: user_id,
        first_name: "firstname",
        last_name: "lastname",
        email: "email",
        email_verified: true,
        account_owner: true,
        locale: "locale",
        collaborator: false,
      )
      session = ShopifyAPI::Auth::Session.new(shop: "my_shop", associated_user: user)

      InMemoryUserSessionStore.store(session, user)

      assert_equal session, InMemoryUserSessionStore.retrieve_by_shopify_user_id(user_id.to_s)
    end
  end
end
