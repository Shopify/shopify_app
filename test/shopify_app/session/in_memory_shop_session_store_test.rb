# frozen_string_literal: true

require_relative "../../test_helper"

module ShopifyApp
  class InMemoryShopSessionStoreTest < ActiveSupport::TestCase
    teardown do
      InMemoryShopSessionStore.clear
    end

    test "retrieving a session by JWT" do
      InMemoryShopSessionStore.repo["abra"] = "something"

      shopify_domain = "abra"
      assert_equal "something", InMemoryShopSessionStore.retrieve_by_shopify_domain(shopify_domain)
    end
  end
end
