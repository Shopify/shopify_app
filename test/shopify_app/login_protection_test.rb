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
end

class LoginProtectionTest < ActionController::TestCase
  tests LoginProtectionController

  setup do
    ShopifyApp::SessionRepository.storage = InMemorySessionStore
  end

  test "calling shop session returns nil when session is nil" do
    with_application_test_routes do
      session[:shopify] = nil
      get :index
      assert_nil @controller.shop_session
    end
  end

  test "calling shop session retreives session from storage" do
    with_application_test_routes do
      session[:shopify] = "foobar"
      get :index
      ShopifyApp::SessionRepository.expects(:retrieve).returns(session).once
      assert @controller.shop_session
    end
  end

  test "shop session is memoized and does not retreive session twice" do
    with_application_test_routes do
      session[:shopify] = "foobar"
      get :index
      ShopifyApp::SessionRepository.expects(:retrieve).returns(session).once
      assert @controller.shop_session
      assert @controller.shop_session
    end
  end

  test "login_again_if_different_shop removes current session and redirects to login url" do
    with_application_test_routes do
      session[:shopify] = "foobar"
      session[:shopify_domain] = "foobar"
      sess = stub(url: 'https://foobar.myshopify.com')
      ShopifyApp::SessionRepository.expects(:retrieve).returns(sess).once
      get :second_login, shop: 'other_shop'
      assert_redirected_to @controller.send(:login_url, shop: 'other_shop')
      assert_nil session[:shopify]
      assert_nil session[:shopify_domain]
    end
  end

  test '#shopify_session with no Shopify session, redirects to the login url' do
    with_application_test_routes do
      get :index, shop: 'foobar'
      assert_redirected_to @controller.send(:login_url, shop: 'foobar')
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

  private

  def with_application_test_routes
    with_routing do |set|
      set.draw do
        get '/' => 'login_protection#index'
        get '/second_login' => 'login_protection#second_login'
      end
      yield
    end
  end
end
