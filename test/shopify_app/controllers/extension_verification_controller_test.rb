require 'test_helper'

class ExtensionController < ExtensionVerificationController
  def extension_action
    head :ok
  end
end

class ExtensionVerificationControllerTest < ActionController::TestCase
  tests ExtensionController

  setup do
    ShopifyApp.configure do |config|
      config.secret = 'secret'
      config.old_secret = 'old_secret'
    end
  end

  test "return unauthorized when hmac is incorrect" do
    with_application_test_routes do
      @request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"] = "invalid_hmac"
      post :extension_action, params: { foo: 'anything' }
      assert_response :unauthorized
    end
  end

  test "responds ok when hmac is correct" do
    with_application_test_routes do
      params = { foo: 'anything' }
      valid_hmac = 'yCGX/RrK4fcuNtr3ztk5tQGsOBjcAzHpGLdMUrbV8yI=' # Valid hmac using the new secret
      @request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"] = valid_hmac
      post 'extension_action', params: params
      assert_response :ok
    end
  end

  private

  def with_application_test_routes
    with_routing do |set|
      set.draw do
        post '/extension_action' => 'extension#extension_action'
      end
      yield
    end
  end
end
