require 'test_helper'

module ShopifyApp
  class SessionRepositoryTest < ActiveSupport::TestCase
    test "retrieving a user session by JWT" do
      SessionRepository.user_storage = InMemoryUserSessionStore

      payload = { 'sub' => 'abra' }
      InMemoryUserSessionStore.expects(:retrieve_by_jwt).with(payload)

      InMemoryUserSessionStore.retrieve_by_jwt(payload)
    end

    test "retrieving a shop session by JWT" do
      SessionRepository.shop_storage = InMemoryShopSessionStore

      payload = { 'sub' => 'abra' }
      InMemoryShopSessionStore.expects(:retrieve_by_jwt).with(payload)

      InMemoryShopSessionStore.retrieve_by_jwt(payload)
    end
  end
end
