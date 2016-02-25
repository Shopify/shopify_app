require 'test_helper'

class SessionsRoutesTest < ActionController::TestCase

  setup do
    @routes = ShopifyApp::Engine.routes
    ShopifyApp::SessionRepository.storage = InMemorySessionStore
    ShopifyApp.configuration = nil
  end

  test "login routes to sessions#new" do
    assert_routing '/login', { controller: 'shopify_app/sessions', action: "new" }
  end

  test "post login routes to sessions#create" do
    assert_routing({method: 'post', path: '/login'}, { controller: 'shopify_app/sessions', action: "create" })
  end

  test "auth_shopify_callback routes to sessions#callback" do
    assert_routing '/auth/shopify/callback', { controller: 'shopify_app/sessions', action: "callback" }
  end

  test "logout routes to sessions#destroy" do
    assert_routing '/logout', { controller: 'shopify_app/sessions', action: "destroy" }
  end
end
