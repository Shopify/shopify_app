require 'test_helper'


class MockSessionStore < ActiveRecord::Base
  include ShopifyApp::SessionStorage
end


module ShopifyApp
  class UserStorageStrategyTest < ActiveSupport::TestCase

    test "tests that UserStorageStrategy is used for session storage" do
        begin
          ShopifyApp.configuration.per_user_tokens = true
  
          assert_equal MockSessionStore.strategy_klass, ShopifyApp::SessionStorage::UserStorageStrategy
        ensure
          ShopifyApp.configuration.per_user_tokens = false
        end
      end

  end
end
