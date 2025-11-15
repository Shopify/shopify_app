# frozen_string_literal: true

require_relative "../test_helper"

class CallbackRoutesTest < ActionController::TestCase
  setup do
    @routes = ShopifyApp::Engine.routes
    ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
    ShopifyApp.configuration = nil
  end

  teardown do
    ShopifyApp.configuration = nil
  end

  test "auth_shopify_callback routes to callback#callback" do
    assert_routing "/auth/shopify/callback", controller: "shopify_app/callback", action: "callback"
  end

  test "callback route doesn't change with custom root URL because it is in an engine" do
    ShopifyApp.configuration.root_url = "/new-root"
    Rails.application.reload_routes!

    assert_routing "/auth/shopify/callback", controller: "shopify_app/callback", action: "callback"
  end

  test "callback route changes with custom callback URL" do
    ShopifyApp.configuration.login_callback_url = "/other-callback"
    Rails.application.reload_routes!

    assert_routing "/other-callback", controller: "shopify_app/callback", action: "callback"
  end

  test "callback route strips out root URL if both are set since it runs in an engine" do
    ShopifyApp.configuration.root_url = "/new-root"
    ShopifyApp.configuration.login_callback_url = "/new-root/other-callback"
    Rails.application.reload_routes!

    assert_routing "/other-callback", controller: "shopify_app/callback", action: "callback"
  end
end
