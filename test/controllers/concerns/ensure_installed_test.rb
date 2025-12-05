# frozen_string_literal: true

require_relative "../../test_helper"

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
    session = mock
    ShopifyApp::SessionRepository.stubs(:retrieve_shop_session_by_shopify_domain).returns(session)

    client = mock
    ShopifyAPI::Clients::Rest::Admin.expects(:new).with(session: session).returns(client)
    client.expects(:get)

    shopify_domain = "shop1.myshopify.com"

    get :index, params: { shop: shopify_domain }

    assert_response :ok
  end

  test "redirects to login_url (oauth path) to reinstall the app if the store's session token is no longer valid" do
    session = mock
    ShopifyApp::SessionRepository.stubs(:retrieve_shop_session_by_shopify_domain).returns(session)

    client = mock
    ShopifyAPI::Clients::Rest::Admin.expects(:new).with(session: session).returns(client)
    uninstalled_http_error = ShopifyAPI::Errors::HttpResponseError.new(
      response: ShopifyAPI::Clients::HttpResponse.new(
        code: 401,
        headers: {},
        body: "Invalid API key or access token (unrecognized login or wrong password)",
      ),
    )
    client.expects(:get).with(path: "shop").raises(uninstalled_http_error)

    shopify_domain = "shop1.myshopify.com"
    host = "https://tunnel.vision.for.webhooks.com"

    get :index, params: { shop: shopify_domain, host: host }

    url = URI(ShopifyApp.configuration.login_url)
    url.query = URI.encode_www_form(
      shop: shopify_domain,
      host: host,
      return_to: request.fullpath,
    )
    assert_redirected_to url.to_s
  end

  test "throws an error if the shopify error isn't a 401" do
    session = mock
    ShopifyApp::SessionRepository.stubs(:retrieve_shop_session_by_shopify_domain).returns(session)

    client = mock
    ShopifyAPI::Clients::Rest::Admin.expects(:new).with(session: session).returns(client)
    uninstalled_http_error = ShopifyAPI::Errors::HttpResponseError.new(
      response: ShopifyAPI::Clients::HttpResponse.new(
        code: 404,
        headers: {},
        body: "Insert generic message about how we can't find your requests here.",
      ),
    )
    client.expects(:get).with(path: "shop").raises(uninstalled_http_error)

    shopify_domain = "shop1.myshopify.com"

    assert_raises ShopifyAPI::Errors::HttpResponseError do
      get :index, params: { shop: shopify_domain }
    end
  end

  test "throws an error if the request session validation API check fails with an" do
    session = mock
    ShopifyApp::SessionRepository.stubs(:retrieve_shop_session_by_shopify_domain).returns(session)

    client = mock
    ShopifyAPI::Clients::Rest::Admin.expects(:new).with(session: session).returns(client)
    client.expects(:get).with(path: "shop").raises(RuntimeError)

    shopify_domain = "shop1.myshopify.com"

    assert_raises RuntimeError do
      get :index, params: { shop: shopify_domain }
    end
  end

  test "does not perform a session validation check if coming from an embedded" do
    ShopifyApp::SessionRepository.stubs(:retrieve_shop_session_by_shopify_domain)
    ShopifyAPI::Clients::Rest::Admin.expects(:new).never

    get :index, params: { shop: "shop1.myshopify.com" }
  end

  test "detects incompatible controller concerns and raises an error" do
    assert_raise do
      Class.new(ApplicationController) do
        include ShopifyApp::LoginProtection
        include ShopifyApp::EnsureInstalled
      end
    end

    assert_raise do
      Class.new(ApplicationController) do
        include ShopifyApp::EnsureHasSession # since this indirectly includes LoginProtection
        include ShopifyApp::EnsureInstalled
      end
    end

    Class.new(ApplicationController) do
      include ShopifyApp::EnsureInstalled
    end
  end
end
