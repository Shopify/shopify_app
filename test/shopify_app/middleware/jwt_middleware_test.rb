# frozen_string_literal: true
require 'test_helper'

class ShopifyApp::JWTMiddlewareTest < ActiveSupport::TestCase
  def app
    simple_app = lambda { |_|
      [200, { "Content-Type" => "text/yaml" }, ""]
    }

    Rack::Lint.new(ShopifyApp::JWTMiddleware.new(simple_app))
  end

  test 'does not change env if no authorization header' do
    env = Rack::MockRequest.env_for('https://example.com')

    app.call(env)

    assert_nil env['jwt.shopify_domain']
  end

  test 'does not change env if no bearer token' do
    env = Rack::MockRequest.env_for('https://example.com')
    env['HTTP_AUTHORIZATION'] = 'something'

    app.call(env)

    assert_nil env['jwt.shopify_domain']
  end

  test 'does not add the shop to the env if nil shop value' do
    jwt_mock = Struct.new(:shopify_domain, :shopify_user_id).new(nil, 1)
    ShopifyApp::JWT.stubs(:new).with('abc').returns(jwt_mock)

    env = Rack::MockRequest.env_for('https://example.com')
    env['HTTP_AUTHORIZATION'] = 'Bearer abc'

    app.call(env)

    assert_nil env['jwt.shopify_domain']
    assert_equal 1, env['jwt.shopify_user_id']
  end

  test 'does not add the user to the env if nil user value' do
    jwt_mock = Struct.new(:shopify_domain, :shopify_user_id).new('example.myshopify.com', nil)
    ShopifyApp::JWT.stubs(:new).with('abc').returns(jwt_mock)

    env = Rack::MockRequest.env_for('https://example.com')
    env['HTTP_AUTHORIZATION'] = 'Bearer abc'

    app.call(env)

    assert_equal 'example.myshopify.com', env['jwt.shopify_domain']
    assert_nil env['jwt.shopify_user_id']
  end

  test 'sets shopify_domain and shopify_user_id if non-nil values' do
    jwt_mock = Struct.new(:shopify_domain, :shopify_user_id).new('example.myshopify.com', 1)
    ShopifyApp::JWT.stubs(:new).with('abc').returns(jwt_mock)

    env = Rack::MockRequest.env_for('https://example.com')
    env['HTTP_AUTHORIZATION'] = 'Bearer abc'

    app.call(env)

    assert_equal 'example.myshopify.com', env['jwt.shopify_domain']
    assert_equal 1, env['jwt.shopify_user_id']
  end
end

