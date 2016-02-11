require 'test_helper'
require 'action_controller'
require 'action_controller/base'

class WebhooksController < ActionController::Base
  include ShopifyApp::WebhooksController
  def carts_update
    head :ok
  end
end

class WebhooksControllerTest < ActionController::TestCase
  tests WebhooksController

  setup do
    ShopifyApp::SessionRepository.storage = InMemorySessionStore
    ShopifyApp.configure do |config|
      config.secret = 'secret'
    end
  end

  test "#carts_update should verify request" do
    with_application_test_routes do
      data = {foo: :bar}.to_json
      @controller.expects(:hmac_valid?).with(data.to_s).returns(true)
      post :carts_update, data
      assert_response :ok
    end
  end

  test "un-verified request returns unauthorized" do
    with_application_test_routes do
      data = {foo: :bar}.to_json
      @controller.expects(:hmac_valid?).with(data.to_s).returns(false)
      post :carts_update, data
      assert_response :unauthorized
    end
  end

  private

  def with_application_test_routes
    with_routing do |set|
      set.draw do
        get '/carts_update' => 'webhooks#carts_update'
      end
      yield
    end
  end
end
