# frozen_string_literal: true

require "test_helper"

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

  test "#login_on_scope_changes redirects to login when scopes do not match" do
    mock_shop_scopes_mismatch_strategy

    get :index, params: { shop: @shopify_domain, host: @host }

    assert_redirected_to expected_redirect_url
  end

  test "#login_on_scope_changes redirects to the right embedded URL when scopes do not match and embedded mode is enabled" do
    ShopifyApp.configuration.embedded_redirect_url = "/a-redirect-page"

    mock_shop_scopes_mismatch_strategy

    get :index, params: { shop: @shopify_domain, host: @host, embedded: "1" }

    redirect_uri = "https://test.host/login?host=#{CGI.escape(@host)}&return_to=#{CGI.escape(request.fullpath)}&shop=#{@shopify_domain}"
    embedded_url_params = { redirectUri: redirect_uri, shop: @shopify_domain, host: @host }
    embedded_url = "#{ShopifyApp.configuration.embedded_redirect_url}?#{embedded_url_params.to_query}"

    assert_redirected_to embedded_url
  end

  private

  def expected_redirect_url
    login_url = URI(ShopifyApp.configuration.login_url)
    login_url.query = URI.encode_www_form(
      shop: @shopify_domain,
      host: @host,
      return_to: request.fullpath,
    )
    login_url.to_s
  end
end
