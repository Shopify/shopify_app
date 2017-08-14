require 'test_helper'
require 'action_controller'
require 'action_controller/base'

class WebhookVerificationController < ActionController::Base
  self.allow_forgery_protection = true
  protect_from_forgery with: :exception

  include ShopifyApp::WebhookVerification

  def webhook_action
    head :ok
  end
end

class WebhookVerificationTest < ActionController::TestCase
  tests WebhookVerificationController

  setup do
    ShopifyApp.configure do |config|
      config.secret = 'secret'
    end
  end

  test "authorized requests should be successful" do
    with_application_test_routes do
      params = { foo: 'anything' }
      digest = OpenSSL::Digest.new('sha256')
      secret = ShopifyApp.configuration.secret
      valid_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, secret, params.to_query)).strip
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

  private

  def with_application_test_routes
    with_routing do |set|
      set.draw do
        post '/webhook_action' => 'webhook_verification#webhook_action'
      end
      yield
    end
  end
end
