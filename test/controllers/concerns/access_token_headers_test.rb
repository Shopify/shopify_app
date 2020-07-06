# frozen_string_literal: true

class AccessTokenHeadersTest < ActionController::TestCase
  class TestController < ActionController::Base
    include ShopifyApp::AccessTokenHeaders

    def with_header
      response.set_header('Mock-Header', 'mock')
      signal_access_token_required
      render(html: '<h1>Success</h1>')
    end
  end

  tests TestController

  setup do
    Rails.application.routes.draw do
      get '/with-header', to: 'access_token_headers_test/test#with_header'
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test 'sets the X-Shopify-API-Request-Failure-Unauthorized header to true when signalled' do
    get :with_header

    assert_equal true, response.get_header('X-Shopify-API-Request-Failure-Unauthorized')
  end

  test 'does not overwrite previously set headers when setting X-Shopify-API-Request-Failure-Unauthorized header' do
    get :with_header

    assert_equal 'mock', response.get_header('Mock-Header')
    assert_equal true, response.get_header('X-Shopify-API-Request-Failure-Unauthorized')
  end
end
