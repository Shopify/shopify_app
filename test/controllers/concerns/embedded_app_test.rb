# frozen_string_literal: true

require "test_helper"
require "action_view/testing/resolvers"

class EmbeddedAppTest < ActionController::TestCase
  class BaseTestController < ActionController::Base
    abstract!

    self.view_paths = [
      ActionView::FixtureResolver.new(
        "layouts/application.erb"                             => "Application Layout <%= yield %>",
        "layouts/embedded_app.erb"                            => "Embedded App Layout <%= yield %>",
        "embedded_app_test/embedded_app_test/index.html.erb"  => "OK",
      ),
    ]
  end

  class ApplicationTestController < BaseTestController
    layout "application"
  end

  class EmbeddedAppTestController < ApplicationTestController
    include ShopifyApp::EmbeddedApp

    def index; end

    def redirect_to_embed
      redirect_to_embed_app_in_admin
    end
  end

  tests EmbeddedAppTestController

  setup do
    Rails.application.routes.draw do
      get "/embedded_app", to: "embedded_app_test/embedded_app_test#index"
      get "/redirect_to_embed", to: "embedded_app_test/embedded_app_test#redirect_to_embed"
    end
  end

  test "uses the embedded app layout when running in embedded mode" do
    ShopifyApp.configuration.embedded_app = true

    get :index
    assert_template layout: "embedded_app"
  end

  test "uses the default layout when running in non-embedded mode" do
    ShopifyApp.configuration.embedded_app = false

    get :index
    assert_template layout: "application"
  end

  test "sets the ESDK headers when running in embedded mode" do
    ShopifyApp.configuration.embedded_app = true

    get :index
    assert_equal @controller.response.headers["P3P"], 'CP="Not used"'
    assert_not_includes @controller.response.headers, "X-Frame-Options"
  end

  test "does not touch the ESDK headers when running in non-embedded mode" do
    ShopifyApp.configuration.embedded_app = false

    get :index
    assert_not_includes @controller.response.headers, "P3P"
    assert_includes @controller.response.headers, "X-Frame-Options"
  end

  test "#redirect_to_embed_app_in_admin redirects to the embed app in the admin when the host param is present" do
    ShopifyApp.configuration.embedded_app = true

    shop = "my-shop.myshopify.com"
    host = Base64.encode64("#{shop}/admin")
    get :redirect_to_embed, params: { host: host }
    assert_redirected_to "https://#{shop}/admin/apps/#{ShopifyApp.configuration.api_key}"
  end

  test "#redirect_to_embed_app_in_admin redirects to the embed app in the admin when the shop param is present" do
    ShopifyApp.configuration.embedded_app = true

    shop = "my-shop.myshopify.com"
    get :redirect_to_embed, params: { shop: shop }
    assert_redirected_to "https://#{shop}/admin/apps/#{ShopifyApp.configuration.api_key}"
  end

  test "Redirect to login URL when host nor shop param is present" do
    ShopifyApp.configuration.embedded_app = true

    get :redirect_to_embed
    assert_redirected_to ShopifyApp.configuration.login_url
  end

  test "Redirect to root URL when decoded host is not a shopify domain" do
    shop = "my-shop.fakeshopify.com"
    host = Base64.encode64("#{shop}/admin")

    get :redirect_to_embed, params: { host: host }
    assert_redirected_to ShopifyApp.configuration.root_url
  end

  test "Redirect to root URL when shop is not a shopify domain" do
    shop = "my-shop.fakeshopify.com"

    get :redirect_to_embed, params: { shop: shop }
    assert_redirected_to ShopifyApp.configuration.root_url
  end
end
