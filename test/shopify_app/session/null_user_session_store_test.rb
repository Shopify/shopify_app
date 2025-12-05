# frozen_string_literal: true

require_relative "../../test_helper"

module ShopifyApp
  class NullUserSessionStoreTest < ActiveSupport::TestCase
    test ".retrieve returns nil" do
      assert_nil NullUserSessionStore.retrieve("payload")
    end

    test ".store raises ConfigurationError" do
      assert_raises(::ShopifyApp::ConfigurationError) do
        NullUserSessionStore.store("session", "user")
      end
    end

    test ".retrieve_by_jwt returns nil" do
      assert_nil NullUserSessionStore.retrieve_by_shopify_user_id("jwt_payload")
    end
  end
end
