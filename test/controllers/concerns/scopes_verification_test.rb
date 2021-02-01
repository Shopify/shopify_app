# frozen_string_literal: true
require 'test_helper'

class ScopesMismatchController < ActionController::Base
  include ShopifyApp::ScopesVerification

  def index
    render(plain: "OK")
  end

  def current_merchant_scopes
    'read_products, read_orders'
  end

  def configuration_scopes
    'read_products, write_orders'
  end
end

class ScopesMatchController < ActionController::Base
  include ShopifyApp::ScopesVerification

  def index
    render(plain: "OK")
  end

  def current_merchant_scopes
    'read_products, write_orders'
  end

  def configuration_scopes
    'read_products, write_orders, read_orders'
  end
end

class ScopesMismatchTest < ActionController::TestCase
  tests ScopesMismatchController

  setup do
    Rails.application.routes.draw do
      get '/', to: 'scopes_mismatch#index'
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test '#login_on_scope_changes redirects to login when scopes do not match' do
    shopify_domain = 'test-shop.myshopify.com'

    get :index, params: { shop: shopify_domain }

    redirect_url = URI(ShopifyApp.configuration.login_url)
    redirect_url.query = URI.encode_www_form(
      shop: shopify_domain,
      return_to: request.fullpath,
    )

    assert_redirected_to redirect_url.to_s
  end

  test '#login_on_scope_changes redirects to login when current_merchant_scopes are nil' do
    shopify_domain = 'test-shop.myshopify.com'
    @controller.stubs(:current_merchant_scopes).returns(nil)

    get :index, params: { shop: shopify_domain }

    redirect_url = URI(ShopifyApp.configuration.login_url)
    redirect_url.query = URI.encode_www_form(
      shop: shopify_domain,
      return_to: request.fullpath,
    )

    assert_redirected_to redirect_url.to_s
  end
end

class ScopesMatchTest < ActionController::TestCase
  tests ScopesMatchController

  setup do
    Rails.application.routes.draw do
      get '/', to: 'scopes_match#index'
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test '#login_on_scope_changes redirects to login when scopes do not match' do
    shopify_domain = 'test-shop.myshopify.com'

    get :index, params: { shop: shopify_domain }

    assert_response :ok
  end
end

