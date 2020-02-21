require 'test_helper'

module ShopifyApp
  class SessionStorageTest < ActiveSupport::TestCase
    class MockSessionStore < ActiveRecord::Base
      include ShopifyApp::SessionStorage
    end

    test "#storage_strategy is ShopStorageStrategy when per_user_token is false" do
      begin
        ShopifyApp.configuration.per_user_tokens = false
        assert_instance_of(ShopifyApp::SessionStorage::ShopStorageStrategy, MockSessionStore.storage_strategy)
      ensure
        MockSessionStore.storage_strategy = nil
      end
    ensure

    end

    test "#storage_strategy is UserStorageStrategy when per_user_token is true" do
      begin
        ShopifyApp.configuration.per_user_tokens = true
        assert_instance_of(ShopifyApp::SessionStorage::UserStorageStrategy, MockSessionStore.storage_strategy)
      ensure
      MockSessionStore.storage_strategy = nil
      end
    end
  end
end
