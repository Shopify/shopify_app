# frozen_string_literal: true

require "test_helper"

class EnsureInstalledTest < ActionController::TestCase
  class UnauthenticatedTestController < ActionController::Base
    include ShopifyApp::EnsureInstalled

    def index
      render(html: "<h1>Success</ h1>")
    end
  end

  tests UnauthenticatedTestController

  setup do
    Rails.application.routes.draw do
      get "/unauthenticated_test", to: "ensure_installed_test/unauthenticated_test#index"
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
    version = "22.0.0"
    ShopifyApp::Logger.expects(:deprecated).with(regexp_matches(/incompatible concerns/), version)
    ShopifyApp::Logger.stubs(:deprecated).with("Itp will be removed in an upcoming version", "22.0.0")

    Class.new(ApplicationController) do
      include ShopifyApp::LoginProtection
      include ShopifyApp::EnsureInstalled
    end

    ShopifyApp::Logger.expects(:deprecated).with(regexp_matches(/incompatible concerns/), version)
    Class.new(ApplicationController) do
      include ShopifyApp::EnsureHasSession # since this indirectly includes LoginProtection
      include ShopifyApp::EnsureInstalled
    end

    ShopifyApp::Logger.expects(:deprecated).with(regexp_matches(/incompatible concerns/), version)
    authenticated_controller = Class.new(ApplicationController) do
      include ShopifyApp::EnsureHasSession
    end
    Class.new(authenticated_controller) do
      include ShopifyApp::EnsureInstalled
    end

    assert_within_deprecation_schedule(version)
  end

  test "redirects to redirect_for_embedded if app is no longer installed according to the API but not the session repository" do
    session = mock
    ShopifyApp::SessionRepository.stubs(:retrieve_shop_session_by_shopify_domain).returns(session)

    client = mock
    ShopifyAPI::Clients::Rest::Admin.expects(:new).with(session: session).returns(client)
    uninstalled_http_error = ShopifyAPI::Errors::HttpResponseError.new(
      response: ShopifyAPI::Clients::HttpResponse.new(
        code: 404,
        headers: {},
        body: "Invalid API key or access token (unrecognized login or wrong password)",
      ),
    )
    client.expects(:get).with(path: "shop").raises(uninstalled_http_error)

    embedded_redirect_url = "reverse_card_on_reverse_card.embedded.joke"
    ShopifyApp.configuration.stubs(:embedded_redirect_url).returns(embedded_redirect_url)

    @controller.expects(:redirect_for_embedded)
    get :index, params: { shop: "shop1.myshopify.com", embedded: "1" }
  end
end
