require 'test_helper'

module ShopifyApp
  class InMemoryShopSessionStoreTest < ActiveSupport::TestCase
    teardown do
      InMemoryShopSessionStore.clear
    end

    test "retrieving a session by JWT" do
      InMemoryShopSessionStore.repo['abra'] = 'something'

      payload = { 'dest' => 'abra' }
      assert_equal 'something', InMemoryShopSessionStore.retrieve_by_jwt(payload)
    end
  end
end
