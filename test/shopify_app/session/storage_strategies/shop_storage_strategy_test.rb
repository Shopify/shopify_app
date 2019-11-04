require 'test_helper'
# require 'lib/generators/shopify_app/shop_model/templates/shop.rb'


class MockSessionStore < ActiveRecord::Base
  include ShopifyApp::SessionStorage
end


module ShopifyApp
  class ShopStorageStrategyTest < ActiveSupport::TestCase

    test "tests that ShopStorageStrategy is used for session storage" do
      begin
        ShopifyApp.configuration.per_user_tokens = false

        assert_equal MockSessionStore.strategy_klass, ShopifyApp::SessionStorage::ShopStorageStrategy
      ensure
        ShopifyApp.configuration.per_user_tokens = false
      end
    end

  end
end
