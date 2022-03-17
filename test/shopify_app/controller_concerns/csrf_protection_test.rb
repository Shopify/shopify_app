# frozen_string_literal: true

class CsrfProtectionController < ActionController::Base
  include ShopifyApp::LoginProtection
  include ShopifyApp::CsrfProtection

  def authenticity_token
    render(json: { authenticity_token: form_authenticity_token })
  end

  def csrf_test
    head(:ok)
  end
end

class CsrfProtectionTest < ActionDispatch::IntegrationTest
  setup do
    @authenticity_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    Rails.application.routes.draw do
      get "/authenticity_token", to: "csrf_protection#authenticity_token"
      post "/csrf_protection_test", to: "csrf_protection#csrf_test"
    end
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @authenticity_protection
  end

  test "it raises an invalid authenticity token error if a valid session token or csrf token is not provided" do
    assert_raises ActionController::InvalidAuthenticityToken do
      post "/csrf_protection_test"
    end
  end

  test "it does not raise if a valid CSRF token was provided" do
    get "/authenticity_token"

    csrf_token = JSON.parse(response.body)["authenticity_token"]

    post "/csrf_protection_test", headers: { "X-CSRF-Token": csrf_token }

    assert_response :ok
  end

  test "it does not raise if a valid session token was provided" do
    post "/csrf_protection_test", env: { "jwt.shopify_domain": "exampleshop.myshopify.com" }

    assert_response :ok
  end
end
