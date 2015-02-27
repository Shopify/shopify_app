require 'test_helper'

class ConfigurationTest < Minitest::Test

  def test_configure
    ShopifyApp.configure do |config|
      config.embedded_app = true
    end

    assert_equal true, ShopifyApp.configuration.embedded_app
  end

  def test_routes_enabled
    assert_equal true, ShopifyApp.configuration.routes_enabled?
  end

end
