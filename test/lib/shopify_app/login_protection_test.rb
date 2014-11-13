require 'test_helper'
require 'action_controller'

class LoginProtectionController < ActionController::Base
  include ShopifyApp::LoginProtection
  helper_method :shop_session

  def index
    render nothing: true
  end
end

class LoginProtectionTest < ActionController::TestCase
  tests LoginProtectionController

  def setup
    ShopifySessionRepository.storage = InMemorySessionStore
  end

  def test_calling_shop_session_returns_nil_when_session_is_nil
    with_application_test_routes do
      session[:shopify] = nil
      get :index
      assert_nil @controller.shop_session
    end
  end

  def test_calling_shop_session_retreives_session_from_storage
    with_application_test_routes do
      session[:shopify] = "foobar"
      get :index
      ShopifySessionRepository.expects(:retrieve).returns(session).once
      @controller.shop_session
    end
  end

  def test_shop_session_is_memoized_and_does_not_retreive_session_twice
    with_application_test_routes do
      session[:shopify] = "foobar"
      get :index
      ShopifySessionRepository.expects(:retrieve).returns(session).once
      @controller.shop_session
      @controller.shop_session
    end
  end

  def with_application_test_routes
    with_routing do |set|
      set.draw do
        get '/' => 'login_protection#index'
      end
      yield
    end
  end
end
