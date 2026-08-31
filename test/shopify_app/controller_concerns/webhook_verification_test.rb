# frozen_string_literal: true

require_relative "../../test_helper"
require "action_controller"
require "action_controller/base"

class WebhookVerificationController < ActionController::Base
  self.allow_forgery_protection = true
  protect_from_forgery with: :exception

  include ShopifyApp::WebhookVerification

  def webhook_action
    head(:ok)
  end

  def shop_domain_action
    render(plain: shop_domain)
  end
end

class WebhookVerificationTest < ActionController::TestCase
  tests WebhookVerificationController

  setup do
    ShopifyApp.configure do |config|
      config.secret = "secret"
      config.old_secret = "old_secret"
    end
  end

  test "webhook verification doesn't blow up when old_secret is nil" do
    ShopifyApp.configuration.old_secret = nil

    with_application_test_routes do
      @request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"] = "invalid_hmac"
      post :webhook_action, params: { foo: "anything" }
      assert_response :unauthorized
    end
  end

  test "authorized requests should be successful" do
    with_application_test_routes do
      params = { foo: "anything" }
      valid_hmac = "yCGX/RrK4fcuNtr3ztk5tQGsOBjcAzHpGLdMUrbV8yI="
      @request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"] = valid_hmac
      post :webhook_action, params: params
      assert_response :ok
    end
  end

  test "authorized request validated with old secret should be successful" do
    with_application_test_routes do
      params = { foo: "anything" }
      valid_hmac = "XqRcjrSv57VACn6apEO9znyu/wkN1VC7QxdSPwK3Hzs="
      @request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"] = valid_hmac
      post :webhook_action, params: params
      assert_response :ok
    end
  end

  test "un-verified request returns unauthorized" do
    with_application_test_routes do
      @request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"] = "invalid_hmac"
      post :webhook_action, params: { foo: anything }
      assert_response :unauthorized
    end
  end

  test "authorized request with new header format should be successful" do
    with_application_test_routes do
      params = { foo: "anything" }
      valid_hmac = "yCGX/RrK4fcuNtr3ztk5tQGsOBjcAzHpGLdMUrbV8yI="
      @request.headers["HTTP_SHOPIFY_HMAC_SHA256"] = valid_hmac
      post :webhook_action, params: params
      assert_response :ok
    end
  end

  test "un-verified request with new header format returns unauthorized" do
    with_application_test_routes do
      @request.headers["HTTP_SHOPIFY_HMAC_SHA256"] = "invalid_hmac"
      post :webhook_action, params: { foo: "anything" }
      assert_response :unauthorized
    end
  end

  test "new header format takes precedence when both headers present" do
    with_application_test_routes do
      params = { foo: "anything" }
      valid_hmac = "yCGX/RrK4fcuNtr3ztk5tQGsOBjcAzHpGLdMUrbV8yI="
      @request.headers["HTTP_SHOPIFY_HMAC_SHA256"] = valid_hmac      # New format (valid)
      @request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"] = "invalid_hmac" # Legacy format (invalid)
      post :webhook_action, params: params
      assert_response :ok
    end
  end

  test "falls back to legacy header when new header not present" do
    with_application_test_routes do
      params = { foo: "anything" }
      valid_hmac = "yCGX/RrK4fcuNtr3ztk5tQGsOBjcAzHpGLdMUrbV8yI="
      @request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"] = valid_hmac
      post :webhook_action, params: params
      assert_response :ok
    end
  end

  test "shop_domain returns value from new header format" do
    with_application_test_routes do
      @request.headers["HTTP_SHOPIFY_HMAC_SHA256"] = "yCGX/RrK4fcuNtr3ztk5tQGsOBjcAzHpGLdMUrbV8yI="
      @request.headers["HTTP_SHOPIFY_SHOP_DOMAIN"] = "test-shop.myshopify.com"
      post :shop_domain_action, params: { foo: "anything" }
      assert_equal "test-shop.myshopify.com", response.body
    end
  end

  test "shop_domain falls back to legacy header" do
    with_application_test_routes do
      @request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"] = "yCGX/RrK4fcuNtr3ztk5tQGsOBjcAzHpGLdMUrbV8yI="
      @request.headers["HTTP_X_SHOPIFY_SHOP_DOMAIN"] = "legacy-shop.myshopify.com"
      post :shop_domain_action, params: { foo: "anything" }
      assert_equal "legacy-shop.myshopify.com", response.body
    end
  end

  test "shop_domain prefers new header over legacy header" do
    with_application_test_routes do
      @request.headers["HTTP_SHOPIFY_HMAC_SHA256"] = "yCGX/RrK4fcuNtr3ztk5tQGsOBjcAzHpGLdMUrbV8yI="
      @request.headers["HTTP_SHOPIFY_SHOP_DOMAIN"] = "new-shop.myshopify.com"
      @request.headers["HTTP_X_SHOPIFY_SHOP_DOMAIN"] = "legacy-shop.myshopify.com"
      post :shop_domain_action, params: { foo: "anything" }
      assert_equal "new-shop.myshopify.com", response.body
    end
  end

  private

  def with_application_test_routes
    with_routing do |set|
      set.draw do
        post "/webhook_action" => "webhook_verification#webhook_action"
        post "/shop_domain_action" => "webhook_verification#shop_domain_action"
      end
      yield
    end
  end
end
