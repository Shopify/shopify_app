require 'test_helper'
require 'action_controller'
require 'action_controller/base'
require 'action_view/testing/resolvers'

class LoginProtectionController < ActionController::Base
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::LoginProtection
  helper_method :shop_session

  around_action :shopify_session, only: [:index]
  before_action :login_again_if_different_shop, only: [:second_login]

  def index
    render plain: "OK"
  end

  def second_login
    render plain: "OK"
  end

  def redirect
    fullpage_redirect_to("https://example.com")
  end

  def raise_unauthorized
    raise ActiveResource::UnauthorizedAccess.new('unauthorized')
  end
end

class LoginProtectionTest < ActionController::TestCase
  tests LoginProtectionController

  setup do
    ShopifyApp::SessionRepository.storage = ShopifyApp::InMemorySessionStore
  end

  test '#index sets test cookie if embedded app' do
    with_application_test_routes do
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

  test "#shop_session returns nil when session is nil" do
    with_application_test_routes do
      session[:shopify] = nil
      get :index
      assert_nil @controller.shop_session
    end
  end

  test "#shop_session retreives the session from storage" do
    with_application_test_routes do
      session[:shopify] = "foobar"
      get :index
      ShopifyApp::SessionRepository.expects(:retrieve).returns(session).once
      assert @controller.shop_session
    end
  end

  test "#shop_session is memoized and does not retreive session twice" do
    with_application_test_routes do
      session[:shopify] = "foobar"
      get :index
      ShopifyApp::SessionRepository.expects(:retrieve).returns(session).once
      assert @controller.shop_session
      assert @controller.shop_session
    end
  end

  test "#login_again_if_different_shop removes current session and redirects to login url" do
    with_application_test_routes do
      session[:shopify] = "foobar"
      session[:shopify_domain] = "foobar"
      session[:shopify_user] = { 'id' => 1, 'email' => 'foo@example.com' }
      sess = stub(url: 'https://foobar.myshopify.com')
      ShopifyApp::SessionRepository.expects(:retrieve).returns(sess).once
      get :second_login, params: { shop: 'other-shop' }
      assert_redirected_to '/login?shop=other-shop.myshopify.com'
      assert_nil session[:shopify]
      assert_nil session[:shopify_domain]
      assert_nil session[:shopify_user]
    end
  end

  test "#login_again_if_different_shop ignores non-String shop params so that Rails params for Shop model can be accepted" do
    with_application_test_routes do
      session[:shopify] = "foobar"
      session[:shopify_domain] = "foobar"
      sess = stub(url: 'https://foobar.myshopify.com')
      ShopifyApp::SessionRepository.expects(:retrieve).returns(sess).once

      get :second_login, params: { shop: { id: 123, disabled: true } }
      assert_response :ok
    end
  end

  test '#shopify_session with Shopify session, clears top-level auth cookie' do
    with_application_test_routes do
      session['shopify.top_level_oauth'] = true
      sess = stub(url: 'https://foobar.myshopify.com')
      @controller.expects(:shop_session).returns(sess).at_least_once
      ShopifyAPI::Base.expects(:activate_session).with(sess)

      get :index, params: { shop: 'foobar' }
      assert_nil session['shopify.top_level_oauth']
    end
  end

  test '#shopify_session with no Shopify session, redirects to the login url' do
    with_application_test_routes do
      get :index, params: { shop: 'foobar' }
      assert_redirected_to '/login?shop=foobar.myshopify.com'
    end
  end

  test "#shopify_session with no Shopify session, redirects to login_url with \
        shop param of referer" do
    with_application_test_routes do
      @controller.expects(:shop_session).returns(nil)
      request.headers['Referer'] = 'https://example.com/?shop=my-shop.myshopify.com'

      get :index
      assert_redirected_to '/login?shop=my-shop.myshopify.com'
    end
  end

  test '#shopify_session with no Shopify session, redirects to the login url \
        with non-String shop param' do
    with_application_test_routes do
      params = { shop: { id: 123 } }
      get :index, params: params
      assert_redirected_to "/login?#{params.to_query}"
    end
  end

  test '#shopify_session with no Shopify session, sets session[:return_to]' do
    with_application_test_routes do
      get :index, params: { shop: 'foobar' }
      assert_equal '/?shop=foobar.myshopify.com', session[:return_to]
    end
  end

  test '#shopify_session with no Shopify session, sets session[:return_to]\
        with non-String shop param' do
    with_application_test_routes do
      params = { shop: { id: 123 } }
      get :index, params: params
      assert_equal "/?#{params.to_query}", session[:return_to]
    end
  end

  test '#shopify_session with no Shopify session, when the request is an XHR, returns an HTTP 401' do
    with_application_test_routes do
      get :index, params: { shop: 'foobar' }, xhr: true
      assert_equal 401, response.status
    end
  end

  test '#shopify_session when rescuing from unauthorized access, redirects to the login url' do
    with_application_test_routes do
      get :raise_unauthorized, params: { shop: 'foobar' }
      assert_redirected_to '/login?shop=foobar.myshopify.com'
    end
  end

  test '#shopify_session when rescuing from unauthorized access, clears shop session' do
    with_application_test_routes do
      session[:shopify] = 'foobar'
      session[:shopify_domain] = 'foobar'
      session[:shopify_user] = { 'id' => 1, 'email' => 'foo@example.com' }

      get :raise_unauthorized, params: { shop: 'foobar' }

      assert_nil session[:shopify]
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

  private

  def assert_fullpage_redirected(shop_domain, response)
    example_url = "https://example.com"

    assert_template 'shared/redirect'
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
      end
      yield
    end
  end
end
