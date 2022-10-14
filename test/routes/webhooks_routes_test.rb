# frozen_string_literal: true

require "test_helper"

class WebhooksRoutingTest < ActionController::TestCase
  setup do
    @routes = ShopifyApp::Engine.routes
  end

  test "webhooks routing" do
    assert_routing(
      { method: "post", path: "webhooks/test" },
      { controller: "shopify_app/webhooks", action: "receive", type: "test" },
    )
  end
end
