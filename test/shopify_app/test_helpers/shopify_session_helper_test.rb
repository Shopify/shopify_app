# frozen_string_literal: true

require "test_helper"
require "shopify_app/test_helpers/shopify_session_helper"

class ShopifySessionHelpersController < ActionController::Base
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::LoginProtection
  around_action :activate_shopify_session, only: [:index]

  def index
    render(plain: "OK")
  end
end

class ShopifySesssionHelperTest < ActionController::TestCase
  include ShopifyApp::TestHelpers::ShopifySessionHelper
  tests ShopifySessionHelpersController

  test "does not redirect when using the shopify session test helper" do
    with_test_routes do
      shop_domain = "my-shop.myshopify.com"
      setup_shopify_session(session_id: "1", shop_domain: shop_domain)

      get :index

      assert_response :ok
    end
  end

  test "redirects when not using the shopify session test helper" do
    with_test_routes do
      get :index

      assert_response :redirect
    end
  end

  private

  def with_test_routes
    with_routing do |set|
      set.draw do
        resources :shopify_session_helpers, only: [:index]
      end
      yield
    end
  end
end
