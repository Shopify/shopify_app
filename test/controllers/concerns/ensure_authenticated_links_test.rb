# frozen_string_literal: true

require 'test_helper'

class EnsureAuthenticatedLinksTest < ActionController::TestCase
  class TurbolinksTestController < ActionController::Base
    include ShopifyApp::EnsureAuthenticatedLinks

    def root
      render(html: '<h1>Splash Page</ h1>')
    end

    def some_link
      render(html: '<h1>Success</ h1>')
    end

    private

    def jwt_shopify_domain
      request.env['jwt.shopify_domain']
    end

    def current_shopify_domain
      'test-shop.myshopify.com'
    end
  end

  tests TurbolinksTestController

  setup do
    @shop_domain = 'test-shop.myshopify.com'

    Rails.application.routes.draw do
      root to: 'ensure_authenticated_links_test/turbolinks_test#root'
      get '/some_link', to: 'ensure_authenticated_links_test/turbolinks_test#some_link'
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test 'redirects to splash page with a return_to and shop param if no session token is present' do
    get :some_link, params: { shop: @shop_domain }

    expected_path = root_path(return_to: request.fullpath, shop: @shop_domain)

    assert_redirected_to expected_path
  end

  test 'returns the requested resource if a valid session token exists' do
    request.env['jwt.shopify_domain'] = @shop_domain

    get :some_link, params: { shop: @shop_domain }

    assert_response :ok
  end

  test 'redirects to login page if current shopify domain is not found' do
    @controller.expects(:current_shopify_domain).raises(ShopifyApp::LoginProtection::ShopifyDomainNotFound)
    expect_redirect_error(ShopifyApp::LoginProtection::ShopifyDomainNotFound, "Could not determine current shop domain")

    get :some_link

    assert_redirected_to ShopifyApp.configuration.login_url
  end

  private

  def expect_redirect_error(klass, message)
    expected_message = "[ShopifyApp::EnsureAuthenticatedLinks] Redirecting to login: [#{klass}] #{message}"
    Rails.logger.expects(:warn).once.with(expected_message)
  end
end
