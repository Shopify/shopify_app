# frozen_string_literal: true

require_relative "../../test_helper"

class WithShopifyIdTokenController < ActionController::Base
  include ShopifyApp::WithShopifyIdToken

  def index
    render(plain: "index")
  end
end

class WithShopifyIdTokenTest < ActionController::TestCase
  tests WithShopifyIdTokenController

  def setup
    @id_token = "this-is-the-shopify-id-token"
    @auth_header = "Bearer #{@id_token}"
    @jwt_payload = {
      iss: "iss",
      dest: "https://test-shop.myshopify.com",
      aud: ShopifyAPI::Context.api_key,
      sub: "1",
      exp: (Time.now + 10).to_i,
      nbf: 1234,
      iat: 1234,
      jti: "4321",
      sid: "abc123",
    }
  end

  test "#shopify_id_token returns nil if id_token can't be found anywhere" do
    with_application_test_routes do
      get :index

      assert_nil @controller.shopify_id_token
    end
  end

  test "#shopify_id_token returns id token from authorization header" do
    with_application_test_routes do
      request.headers["HTTP_AUTHORIZATION"] = @auth_header
      get :index

      assert_equal @id_token, @controller.shopify_id_token
    end
  end

  test "#shopify_id_token returns nil for invalid authorization header format" do
    [
      nil,
      "Bearer",
      "Bearer ",
      "Bearer#{@id_token}",
      "something-else #{@id_token}",
      "something-else",
    ].each do |invalid_auth_headers|
      with_application_test_routes do
        request.headers["HTTP_AUTHORIZATION"] = invalid_auth_headers
        get :index

        assert_nil @controller.shopify_id_token
      end
    end
  end

  test "#shopify_id_token returns id token from URL params" do
    with_application_test_routes do
      get :index, params: { id_token: @id_token }

      assert_equal @id_token, @controller.shopify_id_token
    end
  end

  test "#shopify_id_token returns id token from authorization header first" do
    with_application_test_routes do
      request.headers["HTTP_AUTHORIZATION"] = "Bearer OK"
      get :index, params: { id_token: "this-should-not-be-returned" }

      assert_equal "OK", @controller.shopify_id_token
    end
  end

  test "#shopify_id_token returns id token from URL params only if authorization header is nil" do
    with_application_test_routes do
      request.headers["HTTP_AUTHORIZATION"] = nil
      get :index, params: { id_token: "OK" }

      assert_equal "OK", @controller.shopify_id_token
    end
  end

  test "#shopify_id_token is memoized" do
    with_application_test_routes do
      request.headers["HTTP_AUTHORIZATION"] = "Bearer OK"
      first = @controller.shopify_id_token
      request.headers["HTTP_AUTHORIZATION"] = "NOT-OK"
      second = @controller.shopify_id_token

      assert_equal first, second, "OK"
    end
  end

  test "#jwt_shopify_domain returns dest from token payload" do
    expected_domain = "test-shop.myshopify.com"
    with_application_test_routes do
      request.headers["HTTP_AUTHORIZATION"] = "Bearer #{jwt_token}"
      get :index

      assert_equal expected_domain, @controller.jwt_shopify_domain
    end
  end

  test "#jwt_shopify_user_id returns sub from token payload" do
    expected_user_id = 1
    with_application_test_routes do
      request.headers["HTTP_AUTHORIZATION"] = "Bearer #{jwt_token}"
      get :index

      assert_equal expected_user_id, @controller.jwt_shopify_user_id
    end
  end

  test "#jwt_expire_at returns exp - 5 seconds from token payload" do
    freeze_time do
      expected_expire_at = (Time.now + 10).to_i
      with_application_test_routes do
        request.headers["HTTP_AUTHORIZATION"] = "Bearer #{jwt_token}"
        get :index

        assert_equal expected_expire_at - 5.seconds, @controller.jwt_expire_at
      end
    end
  end

  def with_application_test_routes
    with_routing do |set|
      set.draw do
        get "/" => "with_shopify_id_token#index"
      end
      yield
    end
  end

  def jwt_token
    JWT.encode(@jwt_payload, ShopifyAPI::Context.api_secret_key, "HS256")
  end
end
