# frozen_string_literal: true

require 'test_helper'

class AccessTokenController < ActionController::Base
  include ShopifyApp::AccessToken
  before_action :signal_access_token_required, only: [:index]

  def index
    render(plain: 'OK')
  end
end

class AccessTokenControllerTest < ActionController::TestCase
  tests AccessTokenController
  include ShopifyApp::AccessToken

  test '#signal_access_token_required sets the X-Shopify-API-Request-Failure-Unauthorized header to true' do
    with_application_test_routes do
      get :index
      assert_equal true, response.get_header('X-Shopify-API-Request-Failure-Unauthorized')
    end
  end

  test '#user_session_expected? returns false when user_storage not configured' do
    ShopifyApp::SessionRepository.user_storage = nil
    refute user_session_expected?
  end

  test '#user_session_expected? returns true when user_storage configured' do
    ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore
    assert user_session_expected?
  end

  private

  def with_application_test_routes
    with_routing do |set|
      set.draw do
        get '/index' => 'access_token#index'
      end
      yield
    end
  end
end
