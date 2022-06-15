# frozen_string_literal: true

require "test_helper"
require "action_controller"
require "action_controller/base"
require "action_view/testing/resolvers"

class LoginProtectionController < ActionController::Base
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::LoginProtection
  helper_method :current_shopify_session, :jwt_expire_at

  around_action :activate_shopify_session, only: [:index]
  before_action :login_again_if_different_user_or_shop, only: [:second_login]

  def index
    render(plain: "OK")
  end

  def index_with_headers
    response.set_header("Mock-Header", "Mock-Value")
    signal_access_token_required
    render(plain: "OK")
  end

  def second_login
    render(plain: "OK")
  end

  def redirect
    fullpage_redirect_to("https://example.com")
  end

  def raise_unauthorized
    raise ShopifyAPI::Errors::HttpResponseError.new(code: 401), "unauthorized"
  end

  def raise_not_found
    raise ShopifyAPI::Errors::HttpResponseError.new(code: 404), "not found"
  end
end

class LoginProtectionControllerTest < ActionController::TestCase
  tests LoginProtectionController

  setup do
    ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
    ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore

    request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) "\
      "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36"
  end

  test "#current_shopify_session returns nil when session is nil" do
    with_application_test_routes do
      session[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = nil
      get :index
      assert_nil @controller.current_shopify_session
    end
  end

  test "#current_shopify_session loads online session if user session expected" do
    shop = "my-shop.myshopify.com"
    ShopifyApp::SessionRepository.shop_storage.stubs(:retrieve_by_shopify_domain)
      .with(shop)
      .returns(mock_session(shop: shop))

    cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = "cookie"
    request.headers["HTTP_AUTHORIZATION"] = "Bearer token"

    ShopifyAPI::Utils::SessionUtils.expects(:load_current_session)
      .with(
        auth_header: "Bearer token",
        cookies: { ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME => "cookie" },
        is_online: true
      )
      .returns(nil)

    with_application_test_routes do
      get :index, params: { shop: shop }
    end
  end

  test "#current_shopify_session loads offline session if user session unexpected" do
    ShopifyApp::SessionRepository.user_storage = nil

    cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = "cookie"
    request.headers["HTTP_AUTHORIZATION"] = "Bearer token"

    ShopifyAPI::Utils::SessionUtils.expects(:load_current_session)
      .with(
        auth_header: "Bearer token",
        cookies: { ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME => "cookie" },
        is_online: false
      )
      .returns(nil)

    with_application_test_routes do
      get :index
    end
  end

  test "#current_shopify_session is nil if token is invalid" do
    cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = "cookie"
    request.headers["HTTP_AUTHORIZATION"] = "Bearer invalid"

    with_application_test_routes do
      get :index
      assert_nil @controller.current_shopify_session
    end
  end

  test "#current_shopify_session is memoized and does not retrieve session twice" do
    shop_session_record = ShopifyAPI::Auth::Session.new(
      shop: "my-shop",
      access_token: "1234",
    )
    with_application_test_routes do
      get :index
      ShopifyAPI::Utils::SessionUtils.expects(:load_current_session).returns(shop_session_record).once
      assert @controller.current_shopify_session
    end
  end

  test "#login_again_if_different_user_or_shop removes current cookie if the session changes" do
    cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = "cookie"

    ShopifyAPI::Utils::SessionUtils.stubs(:load_current_session)
      .returns(ShopifyAPI::Auth::Session.new(shop: "shop", shopify_session_id: "123"))

    with_application_test_routes do
      params = { session: "456" }
      get :second_login, params: params
      assert_nil cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME]
    end
  end

  test "#login_again_if_different_user_or_shop retains current session if params not present" do
    with_application_test_routes do
      cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = "old-cookie"

      ShopifyAPI::Utils::SessionUtils.expects(:load_current_session).returns(
        ShopifyAPI::Auth::Session.new(shop: "some-shop")
      ).once

      get :second_login

      assert_equal "old-cookie", cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME]
    end
  end

  test "#login_again_if_different_user_or_shop removes current session and redirects to login url" do
    with_application_test_routes do
      cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = "old-cookie"

      ShopifyAPI::Utils::SessionUtils.expects(:load_current_session).returns(
        ShopifyAPI::Auth::Session.new(shop: "some-shop")
      ).once

      get :second_login, params: { shop: "other-shop" }
      assert_redirected_to "/login?return_to=%2Fsecond_login%3Fshop%3Dother-shop.myshopify.com"\
        "&shop=other-shop.myshopify.com"

      assert_nil cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME]
    end
  end

  test "#current_shopify_session redirects to login if the loaded session doesn't have enough scope" do
    shop = "my-shop.myshopify.com"
    ShopifyApp::SessionRepository.shop_storage.stubs(:retrieve_by_shopify_domain)
      .with(shop)
      .returns(mock_session(shop: shop))
    ShopifyAPI::Context.stubs(:scope).returns(ShopifyAPI::Auth::AuthScopes.new(["scope1", "scope2"]))

    cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = "cookie"
    request.headers["HTTP_AUTHORIZATION"] = "Bearer token"

    ShopifyAPI::Utils::SessionUtils.stubs(:load_current_session)
      .with(
        auth_header: "Bearer token",
        cookies: { ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME => "cookie" },
        is_online: true
      )
      .returns(
        ShopifyAPI::Auth::Session.new(shop: shop, scope: ["scope1"])
      )

    with_application_test_routes do
      get :index, params: { shop: shop }

      assert_redirected_to "/login?shop=my-shop.myshopify.com"
      assert_nil cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME]
    end
  end

  test "#current_shopify_session does not redirect when sufficient scope" do
    shop = "my-shop.myshopify.com"
    ShopifyApp::SessionRepository.shop_storage.stubs(:retrieve_by_shopify_domain)
      .with(shop)
      .returns(mock_session(shop: shop))
    ShopifyAPI::Context.stubs(:scope).returns(ShopifyAPI::Auth::AuthScopes.new(["scope1"]))

    cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = "cookie"
    request.headers["HTTP_AUTHORIZATION"] = "Bearer token"

    ShopifyAPI::Utils::SessionUtils.stubs(:load_current_session)
      .with(
        auth_header: "Bearer token",
        cookies: { ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME => "cookie" },
        is_online: true
      )
      .returns(
        ShopifyAPI::Auth::Session.new(shop: "some-shop", scope: ["scope1", "scope2"])
      )

    with_application_test_routes do
      get :index, params: { shop: shop }
      assert_response :ok
      assert_equal "cookie", cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME]
    end
  end

  test "#login_again_if_different_user_or_shop ignores non-String shop params so that Rails params for Shop model can be accepted" do
    with_application_test_routes do
      cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = "old-cookie"

      ShopifyAPI::Utils::SessionUtils.expects(:load_current_session).returns(
        ShopifyAPI::Auth::Session.new(shop: "some-shop")
      ).once

      get :second_login, params: { shop: { id: 123, disabled: true } }
      assert_response :ok
    end
  end

  test "#activate_shopify_session with no Shopify session, redirects to the login url" do
    with_application_test_routes do
      get :index, params: { shop: "foobar" }
      assert_redirected_to "/login?shop=foobar.myshopify.com"
    end
  end

  test "#activate_shopify_session with no Shopify session, redirects to a custom config login url" do
    with_custom_login_url "https://domain.com/custom/route/login" do
      with_application_test_routes do
        get :index, params: { shop: "foobar" }
        assert_redirected_to "https://domain.com/custom/route/login?shop=foobar.myshopify.com"
      end
    end
  end

  test "#activate_shopify_session with no Shopify session, redirects to login_url with \
        shop param of referer" do
    with_application_test_routes do
      ShopifyApp.configuration.user_session_repository = nil
      @controller.expects(:current_shopify_session).returns(nil)
      request.headers["Referer"] = "https://example.com/?shop=my-shop.myshopify.com"

      get :index
      assert_redirected_to "/login?shop=my-shop.myshopify.com"
    end
  end

  test "#activate_shopify_session with no Shopify session, redirects to a custom config login url with \
        shop param of referer" do
    with_custom_login_url "https://domain.com/custom/route/login" do
      with_application_test_routes do
        ShopifyApp.configuration.user_session_repository = nil
        @controller.expects(:current_shopify_session).returns(nil)
        request.headers["Referer"] = "https://example.com/?shop=my-shop.myshopify.com"

        get :index
        assert_redirected_to "https://domain.com/custom/route/login?shop=my-shop.myshopify.com"
      end
    end
  end

  test '#activate_shopify_session with no Shopify session, redirects to the login url \
        with non-String shop param' do
    with_application_test_routes do
      params = { shop: { id: 123 } }
      get :index, params: params
      assert_redirected_to "/login?#{params.to_query}"
    end
  end

  test '#activate_shopify_session with no Shopify session, redirects to a custom config login url \
        with non-String shop param' do
    with_custom_login_url "https://domain.com/custom/route/login" do
      with_application_test_routes do
        params = { shop: { id: 123 } }
        get :index, params: params
        assert_redirected_to "https://domain.com/custom/route/login?#{params.to_query}"
      end
    end
  end

  test "#activate_shopify_session with no Shopify session, sets session[:return_to]" do
    with_application_test_routes do
      get :index, params: { shop: "foobar" }
      assert_equal "/?shop=foobar.myshopify.com", session[:return_to]
    end
  end

  test '#activate_shopify_session with no Shopify session, sets session[:return_to]\
        with non-String shop param' do
    with_application_test_routes do
      params = { shop: { id: 123 } }
      get :index, params: params
      assert_equal "/?#{params.to_query}", session[:return_to]
    end
  end

  test "#activate_shopify_session with no Shopify session, when the request is a POST, sets session[:return_to]" do
    with_application_test_routes do
      request.headers["Referer"] = "https://example.com/?id=123"
      post :index, params: { id: "123", shop: "foobar" }
      assert_equal "/?id=123&shop=foobar.myshopify.com", session[:return_to]
    end
  end

  test "#activate_shopify_session with no Shopify session, when the request is an XHR, returns an HTTP 401" do
    with_application_test_routes do
      get :index, params: { shop: "foobar" }, xhr: true
      assert_equal 401, response.status
      assert_match "1", response.headers["X-Shopify-API-Request-Failure-Reauthorize"]
      assert_match "/login?shop=foobar", response.headers["X-Shopify-API-Request-Failure-Reauthorize-Url"]
    end
  end

  test "#activate_shopify_session when rescuing from unauthorized access, closes session" do
    with_application_test_routes do
      cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = "cookie"

      get :raise_unauthorized, params: { shop: "foobar" }
      assert_redirected_to "/login?shop=foobar.myshopify.com"
      assert_nil cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME]
    end
  end

  test "#activate_shopify_session when rescuing from non 401 errors, does not close session" do
    with_application_test_routes do
      cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = "cookie"

      assert_raises(ShopifyAPI::Errors::HttpResponseError) do
        get :raise_not_found, params: { shop: "foobar" }
      end

      assert_equal "cookie", cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME]
    end
  end

  test "#fullpage_redirect_to sends a post message to that shop in the shop param" do
    with_application_test_routes do
      example_shop = "shop.myshopify.com"
      get :redirect, params: { shop: example_shop }
      assert_fullpage_redirected(example_shop, response)
    end
  end

  test "#fullpage_redirect_to, when the shop params is missing, sends a post message to the shop in the session" do
    with_application_test_routes do
      example_shop = "shop.myshopify.com"
      ShopifyAPI::Utils::SessionUtils.expects(:load_current_session)
        .returns(ShopifyAPI::Auth::Session.new(shop: example_shop))
      get :redirect
      assert_fullpage_redirected(example_shop, response)
    end
  end

  test "#fullpage_redirect_to raises an exception when no Shopify domains are available" do
    with_application_test_routes do
      ShopifyAPI::Utils::SessionUtils.expects(:load_current_session)
        .returns(nil)
      assert_raise ShopifyApp::LoginProtection::ShopifyDomainNotFound do
        get :redirect
      end
    end
  end

  test "#fullpage_redirect_to skips rendering layout" do
    with_application_test_routes do
      example_shop = "shop.myshopify.com"
      get :redirect, params: { shop: example_shop }
      rendered_templates = @_templates.keys
      assert_equal(["shopify_app/shared/redirect"], rendered_templates)
    end
  end

  test "#fullpage_redirect_to, when not an embedded app, does a regular redirect" do
    ShopifyApp.configuration.embedded_app = false

    with_application_test_routes do
      get :redirect
      assert_redirected_to "https://example.com"
    end
  end

  test "signal_access_token_required sets X-Shopify-API-Request-Unauthorized header" do
    with_application_test_routes do
      get :index_with_headers
      assert_equal "true", response.get_header("X-Shopify-API-Request-Failure-Unauthorized")
    end
  end

  test "signal_access_token_required does not overwrite previously set headers" do
    with_application_test_routes do
      get :index_with_headers
      assert_equal "Mock-Value", response.get_header("Mock-Header")
    end
  end

  test "#jwt_expire_at returns jwt expire at with 5s gap" do
    expire_at = 2.hours.from_now.to_i

    with_application_test_routes do
      request.env["jwt.expire_at"] = expire_at
      get :index

      assert_equal expire_at - 5.seconds, @controller.jwt_expire_at
    end
  end

  private

  def assert_fullpage_redirected(shop_domain, _response)
    example_url = "https://example.com"

    assert_template("shared/redirect")
    assert_select "[id=redirection-target]", 1 do |elements|
      assert_equal "{\"myshopifyUrl\":\"https://#{shop_domain}\",\"url\":\"#{example_url}\"}",
        elements.first["data-target"]
    end
  end

  def with_application_test_routes
    with_routing do |set|
      set.draw do
        get "/" => "login_protection#index"
        get "/second_login" => "login_protection#second_login"
        get "/redirect" => "login_protection#redirect"
        get "/raise_unauthorized" => "login_protection#raise_unauthorized"
        get "/raise_not_found" => "login_protection#raise_not_found"
        get "/index_with_headers" => "login_protection#index_with_headers"
      end
      yield
    end
  end

  def with_custom_login_url(url)
    original_url = ShopifyApp.configuration.login_url.dup

    ShopifyApp.configure { |config| config.login_url = url }
    yield
  ensure
    ShopifyApp.configure { |config| config.login_url = original_url }
  end

  def mock_associated_user
    ShopifyAPI::Auth::AssociatedUser.new(
      id: 100,
      first_name: "John",
      last_name: "Doe",
      email: "johndoe@email.com",
      email_verified: true,
      account_owner: false,
      locale: "en",
      collaborator: true
    )
  end
end
