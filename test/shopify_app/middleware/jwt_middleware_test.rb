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

  test "does not change env if no authorization header" do
    env = Rack::MockRequest.env_for("https://example.com")

    app.call(env)

    assert_nil env["jwt.shopify_domain"]
  end

  test "does not change env if no bearer token" do
    env = Rack::MockRequest.env_for("https://example.com")
    env["HTTP_AUTHORIZATION"] = "something"

    app.call(env)

    assert_nil env["jwt.shopify_domain"]
  end

  test "does not add the shop to the env if nil shop value" do
    jwt_mock = Struct.new(:shopify_domain, :shopify_user_id, :expire_at).new(nil, 1, nil)
    ShopifyApp::JWT.stubs(:new).with("abc").returns(jwt_mock)

    env = Rack::MockRequest.env_for("https://example.com")
    env["HTTP_AUTHORIZATION"] = "Bearer abc"

    app.call(env)

    assert_nil env["jwt.shopify_domain"]
    assert_equal 1, env["jwt.shopify_user_id"]
    assert_nil env["jwt.expire_at"]
  end

  test "does not add the user to the env if nil user value" do
    jwt_mock = Struct.new(:shopify_domain, :shopify_user_id, :expire_at).new("example.myshopify.com", nil, nil)
    ShopifyApp::JWT.stubs(:new).with("abc").returns(jwt_mock)

    env = Rack::MockRequest.env_for("https://example.com")
    env["HTTP_AUTHORIZATION"] = "Bearer abc"

    app.call(env)

    assert_equal "example.myshopify.com", env["jwt.shopify_domain"]
    assert_nil env["jwt.shopify_user_id"]
    assert_nil env["jwt.expire_at"]
  end

  test "sets shopify_domain, shopify_user_id and expire_at if non-nil values" do
    expire_at = 2.hours.from_now.to_i
    jwt_mock = Struct.new(:shopify_domain, :shopify_user_id, :expire_at).new("example.myshopify.com", 1, expire_at)
    ShopifyApp::JWT.stubs(:new).with("abc").returns(jwt_mock)

    env = Rack::MockRequest.env_for("https://example.com")
    env["HTTP_AUTHORIZATION"] = "Bearer abc"

    app.call(env)

    assert_equal "example.myshopify.com", env["jwt.shopify_domain"]
    assert_equal 1, env["jwt.shopify_user_id"]
    assert_equal expire_at, env["jwt.expire_at"]
  end

  test "sets the jwt values before calling the next middleware" do
    jwt_mock = Struct.new(:shopify_domain, :shopify_user_id, :expire_at).new("example.myshopify.com", 1, nil)
    ShopifyApp::JWT.stubs(:new).with("abc").returns(jwt_mock)

    env = Rack::MockRequest.env_for("https://example.com")
    env["HTTP_AUTHORIZATION"] = "Bearer abc"

    _, _, body = ShopifyApp::JWTMiddleware.new(simple_app).call(env)

    assert_equal "example.myshopify.com", body
  end
end
