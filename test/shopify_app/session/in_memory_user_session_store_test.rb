# frozen_string_literal: true
require 'test_helper'

module ShopifyApp
  class InMemoryUserSessionStoreTest < ActiveSupport::TestCase
    teardown do
      InMemoryUserSessionStore.clear
    end

    test "retrieving a session by JWT" do
      InMemoryUserSessionStore.repo['abra'] = 'something'

      user_id = 'abra'
      assert_equal 'something', InMemoryUserSessionStore.retrieve_by_shopify_user_id(user_id)
    end
  end
end
