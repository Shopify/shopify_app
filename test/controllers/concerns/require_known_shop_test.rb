# frozen_string_literal: true

require "test_helper"

class RequireKnownShopTest < ActionController::TestCase
  class UnauthenticatedTestController < ActionController::Base
    include ShopifyApp::RequireKnownShop

    def index
      render(html: "<h1>Success</ h1>")
    end
  end

  tests UnauthenticatedTestController

  setup do
    Rails.application.routes.draw do
      get "/unauthenticated_test", to: "require_known_shop_test/unauthenticated_test#index"
    end
  end

  test "redirects to login if no shop param is present" do
    get :index

    assert_redirected_to ShopifyApp.configuration.login_url
  end

  test "redirects to login if no shop is not a valid shopify domain" do
    invalid_shop = "https://shop1.example.com"

    get :index, params: { shop: invalid_shop }

    assert_redirected_to ShopifyApp.configuration.login_url
  end

  test "redirects to login if the shop is not installed" do
    ShopifyApp::SessionRepository.expects(:retrieve_shop_session_by_shopify_domain).returns(false)

    shopify_domain = "shop1.myshopify.com"
    host = "mock-host"

    get :index, params: { shop: shopify_domain, host: host }

    redirect_url = URI("/login")
    redirect_url.query = URI.encode_www_form(
      shop: shopify_domain,
      host: host,
      return_to: request.fullpath,
    )

    assert_redirected_to redirect_url.to_s
  end

  test "returns :ok if the shop is installed" do
    ShopifyApp::SessionRepository.expects(:retrieve_shop_session_by_shopify_domain).returns(true)

    shopify_domain = "shop1.myshopify.com"

    get :index, params: { shop: shopify_domain }

    assert_response :ok
  end

  test "detects incompatible controller concerns" do
    parent_deprecation_setting = ActiveSupport::Deprecation.silenced
    parent_context_log_level = ShopifyAPI::Context.log_level
    ActiveSupport::Deprecation.silenced = false
    ShopifyAPI::Context.stubs(:log_level).returns(:warn)
    assert_deprecated(/incompatible concerns/) do
      Class.new(ApplicationController) do
        include ShopifyApp::RequireKnownShop
        include ShopifyApp::LoginProtection
      end
    end

    assert_deprecated(/incompatible concerns/) do
      Class.new(ApplicationController) do
        include ShopifyApp::RequireKnownShop
        include ShopifyApp::Authenticated # since this indirectly includes LoginProtection
      end
    end

    assert_deprecated(/incompatible concerns/) do
      authenticated_controller = Class.new(ApplicationController) do
        include ShopifyApp::Authenticated
      end

      Class.new(authenticated_controller) do
        include ShopifyApp::RequireKnownShop
      end
    end
    ActiveSupport::Deprecation.silenced = parent_deprecation_setting
    
  end

  test "detects name change deprecation message" do
    parent_deprecation_setting = ActiveSupport::Deprecation.silenced
    parent_context_log_level = ShopifyAPI::Context.log_level
    ActiveSupport::Deprecation.silenced = false
    ShopifyAPI::Context.stubs(:log_level).returns(:warn)

    assert_deprecated(/RequireKnownShop has been replaced by to EnsureInstalled./) do
      Class.new(ApplicationController) do
        include ShopifyApp::RequireKnownShop
      end
    end

    ActiveSupport::Deprecation.silenced = parent_deprecation_setting
    
  end
end
