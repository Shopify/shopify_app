# frozen_string_literal: true

class AccessTokenHeadersTest < ActionController::TestCase
  class TestController < ActionController::Base
    include ShopifyApp::AccessTokenHeaders

    def without_header
      response.set_header('Mock-Header', 'mock')
      render(html: '<h1>Success</h1>')
    end

    def with_header
      signal_access_token_required
      render(html: '<h1>Success</h1>')
    end
  end

  tests TestController

  setup do
    Rails.application.routes.draw do
      get '/with-header', to: 'access_token_headers_test/test#with_header'
      get '/without-header', to: 'access_token_headers_test/test#without_header'
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test 'sets response X-Shopify-Request-Auth-Code header to false when not set' do
    get :without_header

    assert_equal false, response.get_header('X-Shopify-Request-Auth-Code')
  end

  test 'does not change X-Shopify-Request-Auth-Code header if previously set' do
    get :with_header

    assert_equal true, response.get_header('X-Shopify-Request-Auth-Code')
  end

  test 'does not overwrite previously set headers when setting X-Shopify-Request-Auth-Code header' do
    get :without_header

    assert_equal 'mock', response.get_header('Mock-Header')
    assert_equal false, response.get_header('X-Shopify-Request-Auth-Code')
  end
end
