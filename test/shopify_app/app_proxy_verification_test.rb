require 'test_helper'

class AppProxyVerificationController < ActionController::Base
  self.allow_forgery_protection = true
  protect_from_forgery with: :exception

  include ShopifyApp::AppProxyVerification

  def basic
    head :ok
  end
end

class AppProxyVerificationTest < ActionController::TestCase
  tests AppProxyVerificationController

  setup do
    ShopifyApp.configure do |config|
      config.secret = 'secret'
    end
  end

  test 'no_signature' do
    assert_not query_string_valid? 'shop=some-random-store.myshopify.com&path_prefix=%2Fapps%2Fmy-app&timestamp=1466106083'
  end

  test 'basic_query_string' do
    assert query_string_valid? 'shop=some-random-store.myshopify.com&path_prefix=%2Fapps%2Fmy-app&timestamp=1466106083&signature=f5cd7233558b1c50102a6f33c0b63ad1e1072a2fc126cb58d4500f75223cefcd'
    assert_not query_string_valid? 'shop=some-random-store.myshopify.com&path_prefix=%2Fapps%2Fmy-app&timestamp=1466106083&evil=1&signature=f5cd7233558b1c50102a6f33c0b63ad1e1072a2fc126cb58d4500f75223cefcd'
    assert_not query_string_valid? 'shop=some-random-store.myshopify.com&path_prefix=%2Fapps%2Fmy-app&timestamp=1466106083&evil=1&signature=wrongwrong8b1c50102a6f33c0b63ad1e1072a2fc126cb58d4500f75223cefcd'
  end

  test 'query_string_complex_args' do
    assert query_string_valid? 'shop=some-random-store.myshopify.com&path_prefix=%2Fapps%2Fmy-app&timestamp=1466106083&signature=bbf3aa60e098f08919a2ea4c64a388414f164e6a117a63b03479ac7aa9464b4f&foo=bar&baz[1]&baz[2]=b&baz[c[0]]=whatup&baz[c[1]]=notmuch'
    assert query_string_valid? 'shop=some-random-store.myshopify.com&path_prefix=%2Fapps%2Fmy-app&timestamp=1466106083&foo=bar&baz[1]&baz[2]=b&baz[c[0]]=whatup&baz[c[1]]=notmuch&signature=bbf3aa60e098f08919a2ea4c64a388414f164e6a117a63b03479ac7aa9464b4f'
  end

  test 'request with invalid signature should fail' do
    with_test_routes do
      invalid_params = {
        shop: 'some-random-store.myshopify.com',
        path_prefix: '/apps/my-app',
        timestamp: '1466106083',
        signature: 'wrong233558b1c50102a6f33c0b63ad1e1072a2fc126cb58d4500f75223cefcd'
      }
      get :basic, params: invalid_params
      assert_response :unauthorized
    end
  end

  test 'request with a valid signature should pass' do
    with_test_routes do
      valid_params = {
        shop: 'some-random-store.myshopify.com',
        path_prefix: '/apps/my-app',
        timestamp: '1466106083',
        signature: 'f5cd7233558b1c50102a6f33c0b63ad1e1072a2fc126cb58d4500f75223cefcd'
      }
      get :basic, params: valid_params
      assert_response :ok
    end
  end

  private

  def query_string_valid?(query_string)
    AppProxyVerificationController.new.send(:query_string_valid?,query_string)
  end

  def with_test_routes
    with_routing do |set|
      set.draw do
        get '/app_proxy/basic' => 'app_proxy_verification#basic'
      end
      yield
    end
  end
end
