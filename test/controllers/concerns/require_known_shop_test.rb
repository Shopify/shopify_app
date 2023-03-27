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
    session = mock
    ShopifyApp::SessionRepository.stubs(:retrieve_shop_session_by_shopify_domain).returns(session)

    client = mock
    ShopifyAPI::Clients::Rest::Admin.expects(:new).with(session: session).returns(client)
    client.expects(:get)

    shopify_domain = "shop1.myshopify.com"

    get :index, params: { shop: shopify_domain }

    assert_response :ok
  end

  test "detects incompatible controller concerns" do
    replaced_message = "RequireKnownShop has been replaced by EnsureInstalled."\
      " Please use the EnsureInstalled controller concern for the same behavior"

    version = "22.0.0"

    ShopifyApp::Logger.stubs(:deprecated).with("Itp will be removed in an upcoming version", version)
    ShopifyApp::Logger.stubs(:deprecated).with(replaced_message, version)

    ShopifyApp::Logger.expects(:deprecated).with(regexp_matches(/incompatible concerns/), version)

    Class.new(ApplicationController) do
      include ShopifyApp::RequireKnownShop
      include ShopifyApp::LoginProtection
    end

    ShopifyApp::Logger.expects(:deprecated).with(regexp_matches(/incompatible concerns/), version)

    Class.new(ApplicationController) do
      include ShopifyApp::RequireKnownShop
      include ShopifyApp::EnsureHasSession # since this indirectly includes LoginProtection
    end

    ShopifyApp::Logger.expects(:deprecated).with(regexp_matches(/incompatible concerns/), version)

    authenticated_controller = Class.new(ApplicationController) do
      include ShopifyApp::EnsureHasSession
    end

    Class.new(authenticated_controller) do
      include ShopifyApp::RequireKnownShop
    end

    assert_within_deprecation_schedule(version)
  end

  test "detects name change deprecation message" do
    message = "RequireKnownShop has been replaced by EnsureInstalled."\
      " Please use the EnsureInstalled controller concern for the same behavior"
    version = "22.0.0"
    ShopifyApp::Logger.expects(:deprecated).with(message, version)

    Class.new(ApplicationController) do
      include ShopifyApp::RequireKnownShop
    end

    assert_within_deprecation_schedule(version)
  end
end
