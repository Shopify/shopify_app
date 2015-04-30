require 'test_helper'

class ConfigurationTest < ActiveSupport::TestCase

  test "configure" do
    ShopifyApp.configure do |config|
      config.embedded_app = true
    end

    assert_equal true, ShopifyApp.configuration.embedded_app
  end

 test "routes enabled" do
    assert_equal true, ShopifyApp.configuration.routes_enabled?
  end

end
