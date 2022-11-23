# frozen_string_literal: true

require "test_helper"
require "test_helpers/controller"

class ScopesVerificationController < ActionController::Base
  include ShopifyApp::ShopAccessScopesVerification

  def index
    render(plain: "OK")
  end
end

class ShopAccessScopesVerificationControllertest < ActionController::TestCase
  tests ScopesVerificationController

  setup do
    ShopifyApp.configuration.reauth_on_access_scope_changes = true
    @shopify_domain = "test-shop.myshopify.com"
    @host = "https://mock-host/admin"

    Rails.application.routes.draw do
      get "/", to: "scopes_verification#index"
    end
  end

  test "#login_on_scope_changes does nothing if shop scopes match" do
    mock_shop_scopes_match_strategy

    get :index, params: { shop: @shopify_domain, host: @host }

    assert_response :ok
  end

  test "#login_on_scope_changes redirects to re-authorize when scopes do not match" do
    mock_shop_scopes_mismatch_strategy

    get :index, params: { shop: @shopify_domain, host: @host }

    assert_equal actual_client_side_redirect_url, expected_redirect_url
    assert_client_side_redirect(expected_redirect_url)
  end
end
