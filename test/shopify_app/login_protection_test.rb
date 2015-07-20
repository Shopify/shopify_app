require 'test_helper'
require 'action_controller'
require 'action_controller/base'

class LoginProtectionController < ActionController::Base
  include ShopifyApp::LoginProtection
  helper_method :shop_session

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

  test "login_again_if_different_shop removes current session and redirects to login path" do
    with_application_test_routes do
      session[:shopify] = "foobar"
      sess = stub(url: 'https://foobar.myshopify.com')
      ShopifyApp::SessionRepository.expects(:retrieve).returns(sess).once
      get :second_login, shop: 'other_shop'
      assert_redirected_to @controller.send(:login_path, shop: 'other_shop')
      assert_nil session[:shopify]
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
