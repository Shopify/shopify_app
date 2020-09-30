# frozen_string_literal: true
require 'test_helper'

module ShopifyApp
  class InMemoryActualSessionStoreTest < ActiveSupport::TestCase
    teardown do
      InMemoryActualSessionStore.clear
    end

    test "retrieving a session by JWT" do
      InMemoryActualSessionStore.repo['abra'] = 'something'

      shopify_session_id = 'abra'
      assert_equal 'something', InMemoryActualSessionStore.retrieve_by_shopify_session_id(shopify_session_id)
    end
  end
end
