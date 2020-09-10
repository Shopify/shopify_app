# frozen_string_literal: true
require 'test_helper'
require 'action_controller'
require 'action_controller/base'
require 'action_view/testing/resolvers'

class LoginProtectionController < ActionController::Base
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::LoginProtection
  helper_method :current_shopify_session

  around_action :activate_shopify_session, only: [:index]
  before_action :login_again_if_different_user_or_shop, only: [:second_login]
  before_action :update_scopes_if_insufficient_access, only: [:index_with_scope_check]

  def index
    render(plain: "OK")
  end

  def index_with_headers
    response.set_header('Mock-Header', 'Mock-Value')
    signal_access_token_required
    render(plain: "OK")
  end

  def index_with_scope_check
    render(plain: "OK")
  end

  def second_login
    render(plain: "OK")
  end

  def redirect
    fullpage_redirect_to("https://example.com")
  end

  def raise_unauthorized
    raise ActiveResource::UnauthorizedAccess, 'unauthorized'
  end
end

class LoginProtectionControllerTest < ActionController::TestCase
  tests LoginProtectionController

  setup do
    ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
    ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore

    ShopifyApp.configuration.api_key = 'api_key'
    ShopifyApp.configuration.scope = %w(read_products read_themes write_themes).join(',')

    request.env['HTTP_USER_AGENT'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) '\
                                     'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36'
  end

  teardown do
    ShopifyApp.configuration.allow_jwt_authentication = false
  end

  test '#index sets test cookie if embedded app and user agent can partition cookies' do
    with_application_test_routes do
      request.env['HTTP_USER_AGENT'] = 'Version/12.0 Safari'
      get :index
      assert_equal true, session['shopify.cookies_persist']
    end
  end

  test '#index doesn\'t set test cookie if non embedded app' do
    with_application_test_routes do
      ShopifyApp.configuration.embedded_app = false

      get :index
      assert_nil session['shopify.cookies_persist']
    end
  end

  test "#current_shopify_session returns nil when session is nil" do
    with_application_test_routes do
      session[:shop_id] = nil
      get :index
      assert_nil @controller.current_shopify_session
    end
  end

  test "#current_shopify_session retrieves user session using jwt" do
    ShopifyApp.configuration.allow_jwt_authentication = true
    domain = 'https://test.myshopify.io'
    token = 'admin_api_token'
    dest = 'shopify_domain'
    sub = 'shopify_user'

    expected_session = ShopifyAPI::Session.new(
      domain: domain,
      token: token,
      api_version: '2020-01',
    )

    ShopifyApp::SessionRepository.expects(:retrieve_user_session_by_shopify_user_id)
      .at_most(2).with(sub).returns(expected_session)
    ShopifyApp::SessionRepository.expects(:retrieve_user_session).never
    ShopifyApp::SessionRepository.expects(:retrieve_shop_session_by_shopify_domain).never
    ShopifyApp::SessionRepository.expects(:retrieve_shop_session).never

    with_application_test_routes do
      request.env['jwt.shopify_domain'] = dest
      request.env['jwt.shopify_user_id'] = sub
      get :index

      assert_equal expected_session, @controller.current_shopify_session
    end
  end

  test "#current_shopify_session retrieves shop session using jwt" do
    ShopifyApp.configuration.allow_jwt_authentication = true
    domain = 'https://test.myshopify.io'
    token = 'admin_api_token'
    dest = 'test.shopify.com'

    expected_session = ShopifyAPI::Session.new(
      domain: domain,
      token: token,
      api_version: '2020-01',
    )

    ShopifyApp::SessionRepository.expects(:retrieve_user_session_by_shopify_user_id).never
    ShopifyApp::SessionRepository.expects(:retrieve_user_session).never
    ShopifyApp::SessionRepository.expects(:retrieve_shop_session_by_shopify_domain)
      .with(dest).returns(expected_session)
    ShopifyApp::SessionRepository.expects(:retrieve_shop_session).never

    with_application_test_routes do
      request.env['jwt.shopify_domain'] = dest
      get :index

      assert_equal expected_session, @controller.current_shopify_session
    end
  end

  test "#current_shopify_session retrieves using session user_id" do
    with_application_test_routes do
      session[:user_id] = '145'
      get :index
      ShopifyApp::SessionRepository.expects(:retrieve_user_session).with(session[:user_id]).returns(session).once
      assert @controller.current_shopify_session
    end
  end

  test "#current_shopify_session retrieves using shop_id when shopify_user not present" do
    with_application_test_routes do
      session[:shop_id] = "shopify_id"
      get :index
      ShopifyApp::SessionRepository.expects(:retrieve_shop_session).with(session[:shop_id]).returns(session).once
      assert @controller.current_shopify_session
    end
  end

  test "#current_shopify_session retreives the session from storage" do
    with_application_test_routes do
      session[:shop_id] = "foobar"
      get :index
      ShopifyApp::SessionRepository.expects(:retrieve_shop_session).returns(session).once
      assert @controller.current_shopify_session
    end
  end

  test "#current_shopify_session is memoized and does not retreive session twice" do
    with_application_test_routes do
      session[:shop_id] = "foobar"
      get :index
      ShopifyApp::SessionRepository.expects(:retrieve_shop_session).returns(session).once
      assert @controller.current_shopify_session
    end
  end

  test "#login_again_if_different_user_or_shop removes current session if the user changes when in per-user-token mode" do
    with_application_test_routes do
      session[:shop_id] = "1"
      session[:shopify_domain] = "foobar"
      session[:shopify_user] = { 'id' => 1, 'email' => 'foo@example.com' }
      session[:user_session] = 'old-user-session'
      params = { shop: 'foobar', session: 'new-user-session' }
      get :second_login, params: params
      assert_nil session[:shop_id]
      assert_nil session[:shopify_domain]
      assert_nil session[:shopify_user]
      assert_nil session[:user_session]
    end
  end

  test "#login_again_if_different_user_or_shop retains current session if the users session doesn't change" do
    with_application_test_routes do
      session[:shop_id] = "1"
      session[:shopify_domain] = "foobar"
      session[:shopify_user] = { 'id' => 1, 'email' => 'foo@example.com' }
      session[:user_session] = 'old-user-session'
      params = { shop: 'foobar', session: 'old-user-session' }
      get :second_login, params: params
      assert session[:shop_id], "1"
      assert session[:shopify_domain], "foobar"
      assert session[:shopify_user], { 'id' => 1, 'email' => 'foo@example.com' }
      assert session[:user_session], 'old-user-session'
    end
  end

  test "#login_again_if_different_user_or_shop retains current session if params not present" do
    with_application_test_routes do
      session[:shop_id] = "1"
      session[:shopify_domain] = "foobar"
      session[:shopify_user] = { 'id' => 1, 'email' => 'foo@example.com' }
      session[:user_session] = 'old-user-session'
      get :second_login
      assert session[:shop_id], "1"
      assert session[:shopify_domain], "foobar"
      assert session[:shopify_user], { 'id' => 1, 'email' => 'foo@example.com' }
      assert session[:user_session], 'old-user-session'
    end
  end

  test "#login_again_if_different_user_or_shop removes current session and redirects to login url" do
    with_application_test_routes do
      session[:shop_id] = "foobar"
      session[:user_id] = 123
      session[:shopify_domain] = "foobar"
      session[:shopify_user] = { 'id' => 1, 'email' => 'foo@example.com' }
      sess = stub(domain: 'https://foobar.myshopify.com')
      ShopifyApp::SessionRepository.expects(:retrieve_user_session).returns(sess).once
      get :second_login, params: { shop: 'other-shop' }
      assert_redirected_to '/login?return_to=%2Fsecond_login%3Fshop%3Dother-shop.myshopify.com'\
                           '&shop=other-shop.myshopify.com'
      assert_nil session[:shop_id]
      assert_nil session[:shopify_domain]
      assert_nil session[:shopify_user]
    end
  end

  test "#login_again_if_different_user_or_shop ignores non-String shop params so that Rails params for Shop model can be accepted" do
    with_application_test_routes do
      session[:shop_id] = "foobar"
      session[:shopify_domain] = "foobar"
      sess = stub(domain: 'https://foobar.myshopify.com')
      ShopifyApp::SessionRepository.expects(:retrieve_shop_session).returns(sess).once

      get :second_login, params: { shop: { id: 123, disabled: true } }
      assert_response :ok
    end
  end

  test '#activate_shopify_session with only shop_session, clears top-level auth cookie' do
    with_application_test_routes do
      ShopifyApp::SessionRepository.user_storage = nil

      session['shopify.top_level_oauth'] = true
      sess = stub(domain: 'https://foobar.myshopify.com')
      @controller.expects(:current_shopify_session).returns(sess).at_least_once
      ShopifyAPI::Base.expects(:activate_session).with(sess)

      get :index, params: { shop: 'foobar' }
      assert_nil session['shopify.top_level_oauth']
    end
  end

  test '#activate_shopify_session with no Shopify session, redirects to the login url' do
    with_application_test_routes do
      get :index, params: { shop: 'foobar' }
      assert_redirected_to '/login?shop=foobar.myshopify.com'
    end
  end

  test '#activate_shopify_session with no Shopify session, redirects to a custom config login url' do
    with_custom_login_url 'https://domain.com/custom/route/login' do
      with_application_test_routes do
        get :index, params: { shop: 'foobar' }
        assert_redirected_to 'https://domain.com/custom/route/login?shop=foobar.myshopify.com'
      end
    end
  end

  test "#activate_shopify_session with no Shopify session, redirects to login_url with \
        shop param of referer" do
    with_application_test_routes do
      ShopifyApp.configuration.user_session_repository = nil
      @controller.expects(:current_shopify_session).returns(nil)
      request.headers['Referer'] = 'https://example.com/?shop=my-shop.myshopify.com'

      get :index
      assert_redirected_to '/login?shop=my-shop.myshopify.com'
    end
  end

  test "#activate_shopify_session with no Shopify session, redirects to a custom config login url with \
        shop param of referer" do
    with_custom_login_url 'https://domain.com/custom/route/login' do
      with_application_test_routes do
        ShopifyApp.configuration.user_session_repository = nil
        @controller.expects(:current_shopify_session).returns(nil)
        request.headers['Referer'] = 'https://example.com/?shop=my-shop.myshopify.com'

        get :index
        assert_redirected_to 'https://domain.com/custom/route/login?shop=my-shop.myshopify.com'
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
    with_custom_login_url 'https://domain.com/custom/route/login' do
      with_application_test_routes do
        params = { shop: { id: 123 } }
        get :index, params: params
        assert_redirected_to "https://domain.com/custom/route/login?#{params.to_query}"
      end
    end
  end

  test '#activate_shopify_session with no Shopify session, sets session[:return_to]' do
    with_application_test_routes do
      get :index, params: { shop: 'foobar' }
      assert_equal '/?shop=foobar.myshopify.com', session[:return_to]
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

  test '#activate_shopify_session with no Shopify session, when the request is a POST, sets session[:return_to]' do
    with_application_test_routes do
      request.headers['Referer'] = 'https://example.com/?id=123'
      post :index, params: { id: '123', shop: 'foobar' }
      assert_equal '/?id=123&shop=foobar.myshopify.com', session[:return_to]
    end
  end

  test '#activate_shopify_session with no Shopify session, when the request is an XHR, returns an HTTP 401' do
    with_application_test_routes do
      get :index, params: { shop: 'foobar' }, xhr: true
      assert_equal 401, response.status
    end
  end

  test '#activate_shopify_session with shop_session and no user_session when \
        user_session expected returns an HTTP 401 when the request is an XHR' do
    # Set up a shop_session
    with_application_test_routes do
      session[:shop_id] = 'foobar'
      get :index, params: { shop: 'foobar' }, xhr: true
      ShopifyApp::SessionRepository.expects(:retrieve_shop_session).returns(session).once
      assert @controller.current_shopify_session
      assert_equal 401, response.status
    end
  end

  test '#activate_shopify_session with shop_session and no user_session when \
        user_session expected redirect to login when the request is not an XHR' do
    # Set up a shop_session
    with_application_test_routes do
      session[:shop_id] = 'foobar'
      get :index, params: { shop: 'foobar' }
      ShopifyApp::SessionRepository.expects(:retrieve_shop_session).returns(session).once
      assert @controller.current_shopify_session
      assert_equal 302, response.status
      assert_redirected_to '/login?shop=foobar.myshopify.com'
    end
  end

  test '#activate_shopify_session when rescuing from unauthorized access, redirects to the login url' do
    with_application_test_routes do
      get :raise_unauthorized, params: { shop: 'foobar' }
      assert_redirected_to '/login?shop=foobar.myshopify.com'
    end
  end

  test '#activate_shopify_session when rescuing from unauthorized access, clears shop session' do
    with_application_test_routes do
      session[:shop_id] = 'foobar'
      session[:shopify_domain] = 'foobar'
      session[:shopify_user] = { 'id' => 1, 'email' => 'foo@example.com' }

      get :raise_unauthorized, params: { shop: 'foobar' }

      assert_nil session[:shop_id]
      assert_nil session[:shopify_domain]
      assert_nil session[:shopify_user]
    end
  end

  test '#fullpage_redirect_to sends a post message to that shop in the shop param' do
    with_application_test_routes do
      example_shop = 'shop.myshopify.com'
      get :redirect, params: { shop: example_shop }
      assert_fullpage_redirected(example_shop, response)
    end
  end

  test '#fullpage_redirect_to, when the shop params is missing, sends a post message to the shop in the jwt' do
    ShopifyApp.configuration.allow_jwt_authentication = true
    domain = 'shop.myshopify.com'

    with_application_test_routes do
      request.env['jwt.shopify_domain'] = domain
      get :redirect
      assert_fullpage_redirected(domain, response)
    end
  end

  test '#fullpage_redirect_to, when the shop params is missing, sends a post message to the shop in the session' do
    with_application_test_routes do
      example_shop = 'shop.myshopify.com'
      session[:shopify_domain] = example_shop
      get :redirect
      assert_fullpage_redirected(example_shop, response)
    end
  end

  test '#fullpage_redirect_to raises an exception when no Shopify domains are available' do
    with_application_test_routes do
      session[:shopify_domain] = nil
      assert_raise ShopifyApp::LoginProtection::ShopifyDomainNotFound do
        get :redirect
      end
    end
  end

  test '#fullpage_redirect_to skips rendering layout' do
    with_application_test_routes do
      example_shop = 'shop.myshopify.com'
      get :redirect, params: { shop: example_shop }
      rendered_templates = @_templates.keys
      assert_equal(['shopify_app/shared/redirect'], rendered_templates)
    end
  end

  test '#fullpage_redirect_to, when not an embedded app, does a regular redirect' do
    ShopifyApp.configuration.embedded_app = false

    with_application_test_routes do
      get :redirect
      assert_redirected_to 'https://example.com'
    end
  end

  test 'signal_access_token_required sets X-Shopify-API-Request-Unauthorized header' do
    with_application_test_routes do
      get :index_with_headers
      assert_equal true, response.get_header('X-Shopify-API-Request-Failure-Unauthorized')
    end
  end

  test 'signal_access_token_required does not overwrite previously set headers' do
    with_application_test_routes do
      get :index_with_headers
      assert_equal 'Mock-Value', response.get_header('Mock-Header')
    end
  end

  test '#update_scopes_if_insufficient_access signals insufficient scopes if shop scopes dont match expected' do
    ShopifyApp.configuration.allow_jwt_authentication = true
    domain = 'https://test.myshopify.io'
    token = 'admin_api_token'

    expected_session = ShopifyAPI::Session.new(
      domain: domain,
      token: token,
      api_version: '2020-01',
      extra: { scopes: %w(read_products read_themes) }
    )

    ShopifyApp::SessionRepository.expects(:retrieve_shop_session_by_shopify_domain)
      .with(domain).returns(expected_session)

    with_application_test_routes do
      request.env['jwt.shopify_domain'] = domain
      get :index_with_scope_check

      assert_equal 403, response.status
      assert_equal true, response.get_header('X-Shopify-Insufficient-Scopes')
    end
  end

  test '#update_scopes_if_insufficient_access does not signal insufficient scopes if shop scopes match as expected' do
    ShopifyApp.configuration.allow_jwt_authentication = true
    domain = 'https://test.myshopify.io'
    token = 'admin_api_token'

    expected_session = ShopifyAPI::Session.new(
      domain: domain,
      token: token,
      api_version: '2020-01',
      extra: { scopes: ShopifyApp.configuration.scope.split(',') }
    )

    ShopifyApp::SessionRepository.expects(:retrieve_shop_session_by_shopify_domain)
      .with(domain).returns(expected_session)

    with_application_test_routes do
      request.env['jwt.shopify_domain'] = domain
      get :index_with_scope_check

      assert_equal 200, response.status
      assert_nil response.get_header('X-Shopify-Insufficient-Scopes')
    end
  end

  private

  def assert_fullpage_redirected(shop_domain, _response)
    example_url = "https://example.com"

    assert_template('shared/redirect')
    assert_select '[id=redirection-target]', 1 do |elements|
      assert_equal "{\"myshopifyUrl\":\"https://#{shop_domain}\",\"url\":\"#{example_url}\"}",
        elements.first['data-target']
    end
  end

  def with_application_test_routes
    with_routing do |set|
      set.draw do
        get '/' => 'login_protection#index'
        get '/second_login' => 'login_protection#second_login'
        get '/redirect' => 'login_protection#redirect'
        get '/raise_unauthorized' => 'login_protection#raise_unauthorized'
        get '/index_with_headers' => 'login_protection#index_with_headers'
        get '/index_with_scope_check' => 'login_protection#index_with_scope_check'
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
end
