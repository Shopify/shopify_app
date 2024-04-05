# frozen_string_literal: true

require "test_helper"

module Shopify
  class AfterAuthenticateJob < ActiveJob::Base
    def perform; end
  end
end

module ShopifyApp
  APP_API_KEY = "my_app_api_key"
  class SessionsControllerTest < ActionController::TestCase
    setup do
      @routes = ShopifyApp::Engine.routes
      ShopifyApp.configuration.api_version = ShopifyAPI::LATEST_SUPPORTED_ADMIN_VERSION
      ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
      ShopifyApp::SessionRepository.user_storage = nil
      ShopifyApp.configuration.wip_new_embedded_auth_strategy = false
      ShopifyApp.configuration.api_key = APP_API_KEY
      ShopifyAppConfigurer.setup_context # need to reset context after config changes

      I18n.locale = :en

      request.env["HTTP_USER_AGENT"] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML,
                 like Gecko) Chrome/69.0.3497.100 Safari/537.36'
    end

    test "#new renders the redirect layout if user agent is not set" do
      request.env["HTTP_USER_AGENT"] = nil
      get :new, params: { shop: "my-shop" }
      assert_template "shared/redirect"
    end

    test "#new renders the redirect layout if user agent is Shopify Mobile (Android)" do
      request.env["HTTP_USER_AGENT"] = 'Shopify Mobile/Android/8.12.0 (Build 12005 with API 28 on Google
                                        Android SDK built for x86) MobileMiddlewareSupported Mozilla/5.0
                                        (Linux; Android 9; Android SDK built for x86 Build/PSR1.180720.075; wv)
                                        AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/69.0.3497.100
                                        Mobile Safari/537.36'
      get :new, params: { shop: "my-shop" }
      assert_template "shared/redirect"
    end

    test "#new renders the redirect layout if user agent is Shopify Mobile (iOS)" do
      request.env["HTTP_USER_AGENT"] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 12_0 like Mac OS X)
                                        AppleWebKit/ 604.1.21 (KHTML, like Gecko) Version/ 12.0 Mobile/17A6278a
                                        Safari/602.1.26 MobileMiddlewareSupported
                                        Shopify Mobile/iOS/8.12.0 (iPad4,7/com.shopify.ShopifyInternal/12.0.0)'
      get :new, params: { shop: "my-shop" }
      assert_template "shared/redirect"
    end

    test "#new renders the redirect layout if user agent is Shopify POS (Android)" do
      request.env["HTTP_USER_AGENT"] = 'com.jadedpixel.pos Shopify POS Dalvik/2.1.0
                  (Linux; U; Android 7.0; Android SDK built for x86 Build/NYC)
                  POS - Debug 2.4.8 (f1d442c789)/3405 Mozilla/5.0
                  (Linux; Android 7.0; Android SDK built for x86 Build/NYC; wv)
                  AppleWebKit/537.36 (KHTML, like Gecko)Version/4.0 Chrome/64.0.3282.137 Safari/537.36'
      get :new, params: { shop: "my-shop" }
      assert_template "shared/redirect"
    end

    test "#new renders the redirect layout if user agent is Shopify POS (Android React Native)" do
      request.env["HTTP_USER_AGENT"] = "com.jadedpixel.pos Shopify POS/4.24.0-mal+30112/Android/9/google/Android SDK " \
        "built for x86/development MobileMiddlewareSupported"

      get :new, params: { shop: "my-shop" }
      assert_template "shared/redirect"
    end

    test "#new renders the redirect layout if user agent is Shopify POS (iOS)" do
      request.env["HTTP_USER_AGENT"] = "com.jadedpixel.pos Shopify POS/4.7 (iPad; iOS 11.0.1; Scale/2.00)"
      get :new, params: { shop: "my-shop" }
      assert_template "shared/redirect"
    end

    test "#new redirects to the top-level login if a valid shop param exists" do
      shopify_domain = "my-shop.myshopify.com"
      get :new, params: { shop: "my-shop" }
      assert_redirected_to_top_level(shopify_domain)
    end

    test "#new redirects to the embedded url if a valid shop param exists and embedded param exists" do
      ShopifyApp.configuration.embedded_redirect_url = "/a-redirect-page"
      shopify_domain = "my-shop.myshopify.com"
      get :new, params: { shop: "my-shop", embedded: 1 }
      assert_redirected_to_embedded(shopify_domain, ShopifyApp.configuration.embedded_redirect_url)
    end

    test "#new stores root path when return_to url is absolute" do
      get :new, params: { shop: "my-shop", return_to: "//example.com" }
      assert_equal "/", session[:return_to]
    end

    test "#new stores only relative path for return_to in the session" do
      get :new, params: { shop: "my-shop", return_to: "/page" }
      assert_equal "/page", session[:return_to]
    end

    test "#new redirects to the auth page if top_level param" do
      ShopifyAPI::Auth::Oauth.stubs(:begin_auth).returns({
        cookie: ShopifyAPI::Auth::Oauth::SessionCookie.new(value: "", expires: Time.now),
        auth_route: "/auth-route",
      })

      get :new, params: { shop: "my-shop", top_level: true }

      assert_redirected_to "/auth-route"
    end

    test "#new starts OAuth requesting offline token if user session is expected but there is no shop session" do
      ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore

      ShopifyAPI::Auth::Oauth.expects(:begin_auth)
        .with(shop: "my-shop.myshopify.com", redirect_path: "/auth/shopify/callback", is_online: false)
        .returns({
          cookie: ShopifyAPI::Auth::Oauth::SessionCookie.new(value: "", expires: Time.now),
          auth_route: "/auth-route",
        })

      get :new, params: { shop: "my-shop", top_level: true }
    end

    test "#new starts OAuth requesting online token if user session is expected and there is a shop session" do
      shop = "my-shop.myshopify.com"

      ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore
      ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
      ShopifyApp::SessionRepository.shop_storage.stubs(:retrieve_by_shopify_domain)
        .with(shop)
        .returns(mock_session(shop: shop))

      ShopifyAPI::Auth::Oauth.expects(:begin_auth)
        .with(shop: shop, redirect_path: "/auth/shopify/callback", is_online: true)
        .returns({
          cookie: ShopifyAPI::Auth::Oauth::SessionCookie.new(value: "", expires: Time.now),
          auth_route: "/auth-route",
        })

      get :new, params: { shop: shop, top_level: true }
    end

    test "#new starts OAuth requesting online token if user session is unexpected" do
      ShopifyAPI::Auth::Oauth.expects(:begin_auth)
        .with(shop: "my-shop.myshopify.com", redirect_path: "/auth/shopify/callback", is_online: false)
        .returns({
          cookie: ShopifyAPI::Auth::Oauth::SessionCookie.new(value: "", expires: Time.now),
          auth_route: "/auth-route",
        })

      get :new, params: { shop: "my-shop", top_level: true }
    end

    test "#new should authenticate the shop if a valid shop param exists non embedded" do
      ShopifyApp.configuration.embedded_app = false
      ShopifyAPI::Auth::Oauth.stubs(:begin_auth).returns({
        auth_route: "/auth-route",
        cookie: ShopifyAPI::Auth::Oauth::SessionCookie.new(value: "nonce", expires: Time.now),
      })
      freeze_time do
        get :new, params: { shop: "my-shop" }

        assert_redirected_to "/auth-route"
        assert_equal "nonce", cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME]
      end
    end

    test "#new should render a full-page if the shop param doesn't exist" do
      get :new
      assert_response :ok
      assert_match(/Shopify App — Installation/, response.body)
    end

    test "#new should render a full-page if the shop param value is not a shop" do
      non_shop_address = "example.com"
      get :new, params: { shop: non_shop_address }
      assert_response :ok
      assert_match(/Shopify App — Installation/, response.body)
    end

    test "#new sets session[:user_tokens] to false if there is no existing offline token" do
      session[:shop_id] = 1
      ShopifyApp::SessionRepository.user_storage.stubs(:present?).returns(true)
      ShopifyApp::SessionRepository.stubs(:retrieve_shop_session).with(session[:shop_id]).returns(nil)

      get :new, params: { shop: "my-shop" }

      refute session[:user_tokens]
    end

    [
      "my-shop",
      "my-shop.myshopify.com",
      "https://my-shop.myshopify.com",
      "http://my-shop.myshopify.com",
    ].each do |good_url|
      test "#create should authenticate the shop for the URL (#{good_url})" do
        shopify_domain = "my-shop.myshopify.com"
        post :create, params: { shop: good_url }
        assert_redirected_to_top_level(shopify_domain)
      end
    end

    [
      "my-shop",
      "my-shop.myshopify.io",
      "https://my-shop.myshopify.io",
      "http://my-shop.myshopify.io",
    ].each do |good_url|
      test "#create should authenticate the shop for the URL (#{good_url}) with custom myshopify_domain" do
        ShopifyApp.configuration.myshopify_domain = "myshopify.io"
        shopify_domain = "my-shop.myshopify.io"
        post :create, params: { shop: good_url }
        assert_redirected_to_top_level(shopify_domain)
      end
    end

    [
      "my-shop",
      "my-shop.myshopify.com",
      "https://my-shop.myshopify.com",
      "http://my-shop.myshopify.com",
    ].each do |good_url|
      test "#create should authenticate the shop for the URL (#{good_url}) with embedded param" do
        ShopifyApp.configuration.embedded_redirect_url = "/a-redirect-page"
        shopify_domain = "my-shop.myshopify.com"
        post :create, params: { shop: good_url, embedded: 1 }
        assert_redirected_to_embedded(shopify_domain, ShopifyApp.configuration.embedded_redirect_url)
      end
    end

    [
      "my-shop",
      "my-shop.myshopify.io",
      "https://my-shop.myshopify.io",
      "http://my-shop.myshopify.io",
    ].each do |good_url|
      test "#create should authenticate the shop for the URL (#{good_url}) with custom myshopify_domain with embedded param" do
        ShopifyApp.configuration.embedded_redirect_url = "/a-redirect-page"
        ShopifyApp.configuration.myshopify_domain = "myshopify.io"
        shopify_domain = "my-shop.myshopify.io"
        post :create, params: { shop: good_url, embedded: 1 }
        assert_redirected_to_embedded(shopify_domain, ShopifyApp.configuration.embedded_redirect_url)
      end
    end

    [
      "my-shop",
      "my-shop.myshopify.com",
      "https://my-shop.myshopify.com",
      "http://my-shop.myshopify.com",
    ].each do |good_url|
      test "#create should redirect to auth route when embedded_redirect_url configured but no embedded param for the URL (#{good_url})" do
        ShopifyApp.configuration.embedded_redirect_url = "/a-redirect-page"
        ShopifyAPI::Auth::Oauth.stubs(:begin_auth).returns({
          cookie: ShopifyAPI::Auth::Oauth::SessionCookie.new(value: "", expires: Time.now),
          auth_route: "/auth-route",
        })
        post :create, params: { shop: good_url }
        assert_redirected_to "/auth-route"
      end
    end

    [
      "my-shop",
      "my-shop.myshopify.io",
      "https://my-shop.myshopify.io",
      "http://my-shop.myshopify.io",
    ].each do |good_url|
      test "#create should redirect to toplevel when embedded_redirect_url configured but no embedded param for the URL (#{good_url}) with custom myshopify_domain" do
        ShopifyApp.configuration.embedded_redirect_url = "/a-redirect-page"
        ShopifyApp.configuration.myshopify_domain = "myshopify.io"
        ShopifyAPI::Auth::Oauth.stubs(:begin_auth).returns({
          cookie: ShopifyAPI::Auth::Oauth::SessionCookie.new(value: "", expires: Time.now),
          auth_route: "/auth-route",
        })
        post :create, params: { shop: good_url }
        assert_redirected_to "/auth-route"
      end
    end

    [
      "my-shop",
      "my-shop.myshopify.com",
      "https://my-shop.myshopify.com",
      "http://my-shop.myshopify.com",
    ].each do |good_url|
      test "#create should redirect to toplevel when embedded_redirect_url is not configured but embedded param sent for the URL (#{good_url})" do
        shopify_domain = "my-shop.myshopify.com"
        post :create, params: { shop: good_url, embedded: 1 }
        assert_redirected_to_top_level(shopify_domain)
      end
    end

    [
      "my-shop",
      "my-shop.myshopify.io",
      "https://my-shop.myshopify.io",
      "http://my-shop.myshopify.io",
    ].each do |good_url|
      test "#create should redirect to toplevel when embedded_redirect_url is not configured but embedded param sent for the URL (#{good_url}) with custom myshopify_domain" do
        ShopifyApp.configuration.myshopify_domain = "myshopify.io"
        shopify_domain = "my-shop.myshopify.io"
        post :create, params: { shop: good_url, embedded: 1 }
        assert_redirected_to_top_level(shopify_domain)
      end
    end

    [
      true,
      false,
    ].each do |use_new_embedded_auth_strategy|
      [
        "myshop.com",
        "myshopify.com",
        "shopify.com",
        "two words",
        "store.myshopify.com.evil.com",
        "/foo/bar",
      ].each do |bad_url|
        test "#create should return an error for a non-myshopify URL (#{bad_url}) -
      when use new embedded auth strategy is #{use_new_embedded_auth_strategy}" do
          ShopifyApp.configuration.stubs(:use_new_embedded_auth_strategy?).returns(use_new_embedded_auth_strategy)
          post :create, params: { shop: bad_url }
          assert_response :redirect
          assert_redirected_to "/"
          assert_equal I18n.t("invalid_shop_url"), flash[:error]
        end
      end

      [
        "myshop.com",
        "myshopify.com",
        "shopify.com",
        "two words",
        "store.myshopify.com.evil.com",
        "/foo/bar",
      ].each do |bad_url|
        test "#create should return an error for a non-myshopify URL (#{bad_url}) with embedded param -
      when use new embedded auth strategy is #{use_new_embedded_auth_strategy}" do
          ShopifyApp.configuration.embedded_redirect_url = "/a-redirect-page"
          post :create, params: { shop: bad_url, embedded: 1 }
          assert_response :redirect
          assert_redirected_to "/"
          assert_equal I18n.t("invalid_shop_url"), flash[:error]
        end
      end

      test "#create should return an error for a non-myshopify URL when using JWT authentication -
      when use new embedded auth strategy is #{use_new_embedded_auth_strategy}" do
        post :create, params: { shop: "invalid domain" }
        assert_response :redirect
        assert_redirected_to "/"
        assert_equal I18n.t("invalid_shop_url"), flash[:error]
      end
    end

    test "#create should render the login page if the shop param doesn't exist" do
      post :create
      assert_redirected_to "/"
    end

    test "#destroy should reset rails session and redirect to login with notice" do
      shop_id = 1
      session[:shopify] = shop_id
      session[:shopify_domain] = "shop1.myshopify.com"
      session[:shopify_user] = { "id" => 1, "email" => "foo@example.com" }
      session[:foo] = "bar"

      get :destroy

      assert_nil session[:shopify]
      assert_nil session[:shopify_domain]
      assert_nil session[:shopify_user]
      assert_nil session[:foo]
      assert_redirected_to login_path
      assert_equal "Successfully logged out", flash[:notice]
    end

    test "#destroy should redirect with notice in spanish" do
      I18n.locale = :es

      get :destroy

      assert_equal "Cerrar sesión", flash[:notice]
    end

    [
      "my-shop",
      "my-shop.myshopify.com",
      "https://my-shop.myshopify.com",
      "http://my-shop.myshopify.com",
      "https://admin.shopify.com/store/my-shop",
    ].each do |good_url|
      test "#create redirects to Shopify managed install path instead if use_new_embedded_auth_strategy is enabled - #{good_url}" do
        ShopifyApp.configuration.wip_new_embedded_auth_strategy = true

        post :create, params: { shop: good_url }

        assert_redirected_to "https://admin.shopify.com/store/my-shop/oauth/install?client_id=#{APP_API_KEY}"
      end
    end

    private

    def assert_redirected_to_top_level(shop_domain, expected_url = nil)
      expected_url ||= "/login?shop=#{shop_domain}\\u0026top_level=true"

      assert_template("shared/redirect")
      assert_select "[id=redirection-target]", 1 do |elements|
        assert_equal "{\"myshopifyUrl\":\"https://#{shop_domain}\",\"url\":\"#{expected_url}\"}",
          elements.first["data-target"]
      end
    end

    def assert_redirected_to_embedded(shop_domain, base_embedded_url = nil)
      assert_not_nil base_embedded_url
      redirect_uri = "https://test.host/login?shop=#{shop_domain}"
      expected_url = base_embedded_url + "?embedded=1&redirectUri=#{CGI.escape(redirect_uri)}" + "&shop=#{shop_domain}"

      assert_redirected_to(expected_url)
    end
  end
end
