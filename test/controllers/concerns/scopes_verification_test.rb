# frozen_string_literal: true
require 'test_helper'

class ScopesVerificationController < ActionController::Base
  include ShopifyApp::ScopesVerification

  def index
    render(plain: "OK")
  end
end

class ScopesVerificationControllertest < ActionController::TestCase
  tests ScopesVerificationController

  setup do
    @shopify_domain = 'test-shop.myshopify.com'

    Rails.application.routes.draw do
      get '/', to: 'scopes_verification#index'
    end
  end

  test '#login_on_scope_changes does nothing if shop scopes match' do
    ShopifyApp.configuration.shop_access_scopes_strategy = AccessScopesStrategyHelpers::MockShopScopesMatchStrategy

    get :index, params: { shop: @shopify_domain }

    assert_response :ok
  end

  test '#login_on_scope_changes redirects to login when scopes do not match' do
    ShopifyApp.configuration.shop_access_scopes_strategy = AccessScopesStrategyHelpers::MockShopScopesMismatchStrategy

    get :index, params: { shop: @shopify_domain }

    assert_redirected_to expected_redirect_url
  end

  private

  def expected_redirect_url
    login_url = URI(ShopifyApp.configuration.login_url)
    login_url.query = URI.encode_www_form(
      shop: @shopify_domain,
      return_to: request.fullpath,
    )
    login_url.to_s
  end
end
