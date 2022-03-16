# frozen_string_literal: true

require "test_helper"

class OrderUpdateJob < ActiveJob::Base
  extend ShopifyAPI::Webhooks::Handler

  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic: topic, shop_domain: shop, webhook: body)
    end
  end

  def perform; end
end

module ShopifyApp
  class WebhooksControllerTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    setup do
      WebhooksController.any_instance.stubs(:verify_request).returns(true)
    end

    test "receives webhook and calls process" do
      ShopifyAPI::Webhooks::Registry.stubs(:process).returns(nil)
      ShopifyAPI::Webhooks::Registry.expects(:process).once
      send_webhook "order_update", { foo: :bar }
      assert_response :ok
    end

    test "returns error for webhook with no job class" do
      assert_raises ShopifyApp::MissingWebhookJobError do
        ShopifyApp::WebhooksManager.send(:webhook_job_klass, "test")
      end
    end

    private

    def send_webhook(name, data)
      post(shopify_app.webhooks_path(name), params: data,
        headers: headers(name))
    end

    def headers(name)
      hmac = OpenSSL::HMAC.digest(
        OpenSSL::Digest.new("sha256"),
        "API_SECRET_KEY",
        "{}"
      )
      headers = {
        "x-shopify-topic" => name,
        "x-shopify-hmac-sha256" => Base64.encode64(hmac),
        "x-shopify-shop-domain" => "test.myshopify.com",
      }
      headers
    end
  end
end
