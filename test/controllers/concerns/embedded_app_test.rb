# frozen_string_literal: true

require "test_helper"
require "action_view/testing/resolvers"

class EmbeddedAppTest < ActionDispatch::IntegrationTest
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

    def current_shopify_domain
      nil
    end
  end

  setup do
    Rails.application.routes.draw do
      get "/embedded_app", to: "embedded_app_test/embedded_app_test#index"
      get "/redirect_to_embed", to: "embedded_app_test/embedded_app_test#redirect_to_embed"
    end
  end

  teardown do
    ShopifyApp.configuration = nil
  end

  test "uses the embedded app layout when running in embedded mode" do
    ShopifyApp.configuration.embedded_app = true

    get embedded_app_path
    assert_template layout: "embedded_app"
  end

  test "uses the default layout when running in non-embedded mode" do
    ShopifyApp.configuration.embedded_app = false

    get embedded_app_path
    assert_template layout: "application"
  end

  test "sets the ESDK headers when running in embedded mode" do
    ShopifyApp.configuration.embedded_app = true

    get embedded_app_path
    assert_equal response.headers["P3P"], 'CP="Not used"'
    assert_not_includes response.headers, "X-Frame-Options"
  end

  test "does not touch the ESDK headers when running in non-embedded mode" do
    ShopifyApp.configuration.embedded_app = false

    get embedded_app_path
    assert_not_includes response.headers, "P3P"
    assert_includes response.headers, "X-Frame-Options"
  end

  test "#redirect_to_embed_app_in_admin redirects to the embed app in the admin when the host param is present" do
    ShopifyApp.configuration.embedded_app = true

    shop = "my-shop.myshopify.com"
    host = Base64.encode64("#{shop}/admin")
    get redirect_to_embed_path, params: { host: host }
    assert_redirected_to "https://#{shop}/admin/apps/#{ShopifyApp.configuration.api_key}/redirect_to_embed"
  end

  test "#redirect_to_embed_app_in_admin redirects to the embed app in the admin when the shop param is present" do
    ShopifyApp.configuration.embedded_app = true

    shop = "my-shop.myshopify.com"
    get redirect_to_embed_path, params: { shop: shop }
    assert_redirected_to "https://#{shop}/admin/apps/#{ShopifyApp.configuration.api_key}/redirect_to_embed"
  end

  test "#redirect_to_embed_app_in_admin keeps original path and params when redirecting to the embed app" do
    ShopifyApp.configuration.embedded_app = true

    shop = "my-shop.myshopify.com"
    host = Base64.encode64("#{shop}/admin")
    get redirect_to_embed_path, params: { shop: shop, foo: "bar", host: host, id_token: "id_token" }
    assert_redirected_to "https://#{shop}/admin/apps/#{ShopifyApp.configuration.api_key}/redirect_to_embed?foo=bar"
  end

  test "Redirect to login URL when host nor shop param is present" do
    ShopifyApp.configuration.embedded_app = true

    get redirect_to_embed_path
    assert_redirected_to ShopifyApp.configuration.login_url
  end

  test "Redirect to root URL when decoded host is not a shopify domain" do
    shop = "my-shop.fakeshopify.com"
    host = Base64.encode64("#{shop}/admin")

    get redirect_to_embed_path, params: { host: host }
    assert_redirected_to ShopifyApp.configuration.root_url
  end

  test "Redirect to root URL when shop is not a shopify domain" do
    shop = "my-shop.fakeshopify.com"

    get redirect_to_embed_path, params: { shop: shop }
    assert_redirected_to ShopifyApp.configuration.root_url
  end

  test "content security policy for frame ancestors contains current_shopify_domain" do
    ShopifyApp.configuration.embedded_app = true
    shop = "my-shop.myshopify.com"
    EmbeddedAppTestController.any_instance.expects(:current_shopify_domain).returns(shop)

    get redirect_to_embed_path
    assert_includes response.headers["Content-Security-Policy"], shop
  end

  test "content security policy for frame ancestors contains myshopify_domain when current_shopify_domain is nil" do
    ShopifyApp.configuration.embedded_app = true
    ShopifyApp.configuration.myshopify_domain = "myshopify.io"
    EmbeddedAppTestController.any_instance.expects(:current_shopify_domain).returns(nil)

    get redirect_to_embed_path
    assert_includes response.headers["Content-Security-Policy"], "*.#{ShopifyApp.configuration.myshopify_domain}"
  end

  test "content security policy for frame ancestors contains unified admin domain" do
    ShopifyApp.configuration.embedded_app = true
    ShopifyApp.configuration.unified_admin_domain = "shop.dev"

    get redirect_to_embed_path
    assert_includes response.headers["Content-Security-Policy"], ShopifyApp.configuration.unified_admin_domain
  end

  test "content security policy includes App Bridge script-src" do
    ShopifyApp.configuration.embedded_app = true

    get redirect_to_embed_path
    assert_includes response.headers["Content-Security-Policy"], "script-src"
    assert_includes response.headers["Content-Security-Policy"], "https://cdn.shopify.com/shopifycloud/app-bridge.js"
  end

  test "content security policy preserves existing script-src directives when adding App Bridge" do
    ShopifyApp.configuration.embedded_app = true

    get redirect_to_embed_path
    csp_header = response.headers["Content-Security-Policy"]

    # Should include both self (default) and App Bridge URL
    assert_includes csp_header, "script-src"
    assert_includes csp_header, "'self'"
    assert_includes csp_header, "https://cdn.shopify.com/shopifycloud/app-bridge.js"
  end
end
