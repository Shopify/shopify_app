# frozen_string_literal: true

require "test_helper"

class ShopifyApp::JWTMiddlewareTest < ActiveSupport::TestCase
  def simple_app
    lambda { |env|
      [200, { "Content-Type" => "text/yaml" }, env["jwt.shopify_domain"] || ""]
    }
  end

  def app
    Rack::Lint.new(ShopifyApp::JWTMiddleware.new(simple_app))
  end

  def setup
    @user_id = 12345678
    @shop = "test-shop.myshopify.io"
    @expire_at = (Time.now + 10).to_i

    payload = {
      iss: "https://#{@shop}/admin",
      dest: "https://#{@shop}",
      aud: ShopifyAPI::Context.api_key,
      sub: @user_id.to_s,
      exp: @expire_at,
      nbf: 1234,
      iat: 1234,
      jti: "4321",
      sid: "abc123",
    }

    @jwt_token = JWT.encode(payload, ShopifyAPI::Context.api_secret_key, "HS256")
    @auth_header = "Bearer #{@jwt_token}"
    @jwt_payload = ShopifyAPI::Auth::JwtPayload.new(@jwt_token)
  end

  test "does not parse JWT unless it's an embedded app" do
    ShopifyApp.configuration.stubs(:embedded_app?).returns(false)

    env = Rack::MockRequest.env_for
    env["HTTP_AUTHORIZATION"] = @auth_header

    ShopifyAPI::Auth::JwtPayload.expects(:new).never

    _, _, body = ShopifyApp::JWTMiddleware.new(simple_app).call(env)

    assert_equal "", body
  end

  test "does not change env if no authorization header or id_token param" do
    env = Rack::MockRequest.env_for

    ShopifyAPI::Auth::JwtPayload.expects(:new).never

    app.call(env)

    assert_nil env["jwt.shopify_domain"]
  end

  test "does not change env if no bearer token" do
    env = Rack::MockRequest.env_for
    env["HTTP_AUTHORIZATION"] = "something"

    ShopifyAPI::Auth::JwtPayload.expects(:new).never

    app.call(env)

    assert_nil env["jwt.shopify_domain"]
  end

  test "accepts JWT from URL id_token param and sets env" do
    env = Rack::MockRequest.env_for("https://example.com/?shop=#{@shop}&id_token=#{@jwt_token}")

    ShopifyAPI::Auth::JwtPayload.expects(:new).with(@jwt_token).returns(@jwt_payload)

    app.call(env)

    assert_envs_are_set(env)
  end

  test "accepts JWT from authorization header and sets env" do
    env = Rack::MockRequest.env_for
    env["HTTP_AUTHORIZATION"] = @auth_header
    ShopifyAPI::Auth::JwtPayload.expects(:new).with(@jwt_token).returns(@jwt_payload)

    app.call(env)

    assert_envs_are_set(env)
  end

  test "sets the jwt values before calling the next middleware" do
    env = Rack::MockRequest.env_for
    env["HTTP_AUTHORIZATION"] = @auth_header

    _, _, body = ShopifyApp::JWTMiddleware.new(simple_app).call(env)

    assert_equal @shop, body
  end

  test "does not set env or raise exception if JWT parsing fails" do
    env = Rack::MockRequest.env_for
    env["HTTP_AUTHORIZATION"] = @auth_header

    ShopifyAPI::Auth::JwtPayload.expects(:new).raises(ShopifyAPI::Errors::InvalidJwtTokenError)

    assert_nothing_raised { app.call(env) }

    assert_envs_are_nil(env)
  end

  test "calls the next middleware even if JWT parsing fails" do
    env = Rack::MockRequest.env_for
    env["HTTP_AUTHORIZATION"] = @auth_header

    ShopifyAPI::Auth::JwtPayload.expects(:new).raises(ShopifyAPI::Errors::InvalidJwtTokenError)

    _, _, body = ShopifyApp::JWTMiddleware.new(simple_app).call(env)

    assert_equal "", body
  end

  private

  def assert_envs_are_set(env)
    assert_equal @shop, env["jwt.shopify_domain"]
    assert_equal @user_id, env["jwt.shopify_user_id"]
    assert_equal @expire_at, env["jwt.expire_at"]
    assert_equal @jwt_token, env["jwt.token"]
  end

  def assert_envs_are_nil(env)
    assert_nil env["jwt.shopify_domain"]
    assert_nil env["jwt.shopify_user_id"]
    assert_nil env["jwt.expire_at"]
  end
end
