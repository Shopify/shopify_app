require 'test_helper'

module ShopifyApp
  class NullShopSessionStoreTest < ActiveSupport::TestCase
    test '.retrieve returns raises ConfigurationError' do
      assert_raises(SessionRepository::ConfigurationError) do
        NullShopSessionStore.retrieve('payload')
      end
    end

    test '.store returns raises ConfigurationError' do
      assert_raises(SessionRepository::ConfigurationError) do
        NullShopSessionStore.store('session', 'user')
      end
    end

    test '.retrieve_by_jwt raises ConfigurationError' do
      assert_raises(SessionRepository::ConfigurationError) do
        NullShopSessionStore.retrieve_by_jwt('jwt_payload')
      end
    end
  end
end
