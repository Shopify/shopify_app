# frozen_string_literal: true

require "test_helper"

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
  end

  test "#shopify_id_token returns nil if id_token can't be found anywhere" do
    with_application_test_routes do
      get :index

      assert_nil @controller.shopify_id_token
    end
  end

  test "#shopify_id_token returns id token from request env" do
    with_application_test_routes do
      request.env["jwt.token"] = @id_token
      get :index

      assert_equal @id_token, @controller.shopify_id_token
    end
  end

  test "#shopify_id_token returns nil if request env is set to nil" do
    with_application_test_routes do
      request.env["jwt.token"] = nil
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

  test "#shopify_id_token returns id token from request env first" do
    with_application_test_routes do
      request.env["jwt.token"] = "OK"
      request.headers["HTTP_AUTHORIZATION"] = "Bearer this-should-not-be-returned"
      get :index, params: { id_token: "this-should-also-not-be-returned" }

      assert_equal "OK", @controller.shopify_id_token
    end
  end

  test "#shopify_id_token returns id token from authorization header only if request env is nil" do
    with_application_test_routes do
      request.env["jwt.token"] = nil
      request.headers["HTTP_AUTHORIZATION"] = "Bearer OK"
      get :index, params: { id_token: "this-should-not-be-returned" }

      assert_equal "OK", @controller.shopify_id_token
    end
  end

  test "#shopify_id_token returns id token from URL params only if request env and authorization header are nil" do
    with_application_test_routes do
      request.env["jwt.token"] = nil
      request.headers["HTTP_AUTHORIZATION"] = nil
      get :index, params: { id_token: "OK" }

      assert_equal "OK", @controller.shopify_id_token
    end
  end

  test "#shopify_id_token is memoized" do
    with_application_test_routes do
      request.env["jwt.token"] = "OK"
      first = @controller.shopify_id_token
      request.env["jwt.token"] = "NOT-OK"
      second = @controller.shopify_id_token

      assert_equal first, second, "OK"
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
end
