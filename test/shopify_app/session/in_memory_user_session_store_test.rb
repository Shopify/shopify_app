require 'test_helper'

module ShopifyApp
  class InMemoryUserSessionStoreTest < ActiveSupport::TestCase
    teardown do
      InMemoryUserSessionStore.clear
    end

    test "retrieving a session by JWT" do
      InMemoryUserSessionStore.repo['abra'] = 'something'

      payload = { 'sub' => 'abra' }
      assert_equal 'something', InMemoryUserSessionStore.retrieve_by_jwt(payload)
    end
  end
end
