require 'test_helper'

class ConfigurationTest < ActiveSupport::TestCase

  setup do
    ShopifyApp.configuration = nil
  end

  test "configure" do
    ShopifyApp.configure do |config|
      config.embedded_app = true
    end

    assert_equal true, ShopifyApp.configuration.embedded_app
  end

  test "routes enabled" do
    ShopifyApp.configure do |config|
      config.routes = true
    end

    assert_equal true, ShopifyApp.configuration.routes_enabled?
  end

  test "disable routes" do
    ShopifyApp.configure do |config|
      config.routes = false
    end

    assert_equal false, ShopifyApp.configuration.routes_enabled?
  end

  test "defaults to myshopify_domain" do
    assert_equal "myshopify.com", ShopifyApp.configuration.myshopify_domain
  end

  test "can set myshopify_domain" do
    ShopifyApp.configure do |config|
      config.myshopify_domain = 'myshopify.io'
    end

    assert_equal "myshopify.io", ShopifyApp.configuration.myshopify_domain
  end

end
