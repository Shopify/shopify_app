# frozen_string_literal: true

require 'test_helper'

class CallbackRoutesTest < ActionController::TestCase
  setup do
    @routes = ShopifyApp::Engine.routes
    ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
    ShopifyApp.configuration = nil
  end

  test 'auth_shopify_callback routes to callback#callback' do
    assert_routing '/auth/shopify/callback', controller: 'shopify_app/callback', action: 'callback'
  end
end
