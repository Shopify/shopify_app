# frozen_string_literal: true

require_relative "../test_helper"

class SessionsRoutesTest < ActionController::TestCase
  setup do
    @routes = ShopifyApp::Engine.routes
    ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
    ShopifyApp.configuration = nil
  end

  teardown do
    ShopifyApp.configuration = nil
  end

  test "login routes to sessions#new" do
    assert_routing "/login", { controller: "shopify_app/sessions", action: "new" }
  end

  test "post login routes to sessions#create" do
    assert_routing({ method: "post", path: "/login" }, { controller: "shopify_app/sessions", action: "create" })
  end

  test "logout routes to sessions#destroy" do
    assert_routing "/logout", { controller: "shopify_app/sessions", action: "destroy" }
  end

  test "patch_shopify_id_token routes to sessions#patch_shopify_id_token" do
    assert_routing "/patch_shopify_id_token", { controller: "shopify_app/sessions", action: "patch_shopify_id_token" }
  end

  test "login route doesn't change with custom root URL because it is in an engine" do
    ShopifyApp.configuration.root_url = "/new-root"
    Rails.application.reload_routes!

    assert_routing "/login", { controller: "shopify_app/sessions", action: "new" }
    assert_routing({ method: "post", path: "/login" }, { controller: "shopify_app/sessions", action: "create" })
  end

  test "login route changes with custom login URL" do
    ShopifyApp.configuration.login_url = "/other-login"
    Rails.application.reload_routes!

    assert_routing "/other-login", { controller: "shopify_app/sessions", action: "new" }
    assert_routing({ method: "post", path: "/other-login" }, { controller: "shopify_app/sessions", action: "create" })
  end

  test "login route strips out root URL if both are set since it runs in an engine" do
    ShopifyApp.configuration.root_url = "/new-root"
    ShopifyApp.configuration.login_url = "/new-root/other-login"
    Rails.application.reload_routes!

    assert_routing "/other-login", { controller: "shopify_app/sessions", action: "new" }
    assert_routing({ method: "post", path: "/other-login" }, { controller: "shopify_app/sessions", action: "create" })
  end
end
