# frozen_string_literal: true
require 'test_helper'

class ShopifyApp::AppBridgeMiddlewareTest < ActiveSupport::TestCase
  def simple_app
    lambda { |env|
      [200, { "Content-Type" => "text/plain" }, ["OK"]]
    }
  end

  def app
    Rack::Lint.new(ShopifyApp::AppBridgeMiddleware.new(simple_app))
  end

  test "adds missing host params" do
    env = Rack::MockRequest.env_for('https://example.com', params: { shop: "test-shop.myshopify.com" })

    app.call(env)

    assert_equal "dGVzdC1zaG9wLm15c2hvcGlmeS5jb20vYWRtaW4", env["rack.request.query_hash"]["host"]
  end
end
