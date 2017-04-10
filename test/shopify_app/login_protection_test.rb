require 'test_helper'
require 'action_controller'
require 'action_controller/base'

class LoginProtectionController < ActionController::Base
  include ShopifyApp::LoginProtection
  helper_method :shop_session

  around_action :shopify_session, only: [:index]
  before_action :login_again_if_different_shop, only: [:second_login]

  def index
    render nothing: true
  end

  def second_login
    render nothing: true
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
    ShopifyApp::SessionRepository.storage = InMemorySessionStore
    ShopifyApp.configuration.embedded_app = true
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
      sess = stub(url: 'https://foobar.myshopify.com')
      ShopifyApp::SessionRepository.expects(:retrieve).returns(sess).once
      get :second_login, shop: 'other_shop'
      assert_redirected_to @controller.send(:main_or_engine_login_url, shop: 'other_shop')
      assert_nil session[:shopify]
      assert_nil session[:shopify_domain]
    end
  end

  test '#shopify_session with no Shopify session, redirects to the login url' do
    with_application_test_routes do
      get :index, shop: 'foobar'
      assert_redirected_to @controller.send(:main_or_engine_login_url, shop: 'foobar')
    end
  end

  test '#shopify_session with no Shopify session, sets session[:return_to]' do
    with_application_test_routes do
      get :index, shop: 'foobar'
      assert_equal '/?shop=foobar', session[:return_to]
    end
  end

  test '#shopify_session with no Shopify session, when the request is an XHR, returns an HTTP 401' do
    with_application_test_routes do
      xhr :get, :index, shop: 'foobar'
      assert_equal 401, response.status
    end
  end

  test '#shopify_session when rescuing from unauthorized access, redirects to the login url' do
    with_application_test_routes do
      get :raise_unauthorized, shop: 'foobar'
      assert_redirected_to @controller.send(:main_or_engine_login_url, shop: 'foobar')
    end
  end

  test '#fullpage_redirect_to sends a post message to that shop in the shop param' do
    with_application_test_routes do
      example_shop = 'shop.myshopify.com'
      get :redirect, shop: example_shop
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

  test '#fullpage_redirect_to, when not an embedded app, does a regular redirect' do
    ShopifyApp.configuration.embedded_app = false

    with_application_test_routes do
      get :redirect
      assert_redirected_to 'https://example.com'
    end

    ShopifyApp.configuration.embedded_app = true
  end

  private

  def assert_fullpage_redirected(shop_domain, response)
    example_url = "https://example.com".to_json
    target_origin = "https://#{shop_domain}".to_json

    post_message_handle = "message: 'Shopify.API.remoteRedirect'"
    post_message_link = "normalizedLink.href = #{example_url}"
    post_message_data = "data: { location: normalizedLink.href }"
    post_message_call = "window.parent.postMessage(data, #{target_origin});"

    assert_includes response.body, post_message_handle
    assert_includes response.body, post_message_link
    assert_includes response.body, post_message_data
    assert_includes response.body, post_message_call
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
