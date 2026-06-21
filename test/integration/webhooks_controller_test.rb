# frozen_string_literal: true

require_relative "../test_helper"

class OrderUpdateJob < ActiveJob::Base
  include ShopifyAPI::Webhooks::WebhookHandler

  class << self
    def handle(topic:, shop:, body:, webhook_id:, api_version:)
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
      assert_raises ::ShopifyApp::MissingWebhookJobError do
        ShopifyApp::WebhooksManager.send(:webhook_job_klass, "test")
      end
    end

    test "receives webhook with new header format and calls process" do
      ShopifyAPI::Webhooks::Registry.stubs(:process).returns(nil)
      ShopifyAPI::Webhooks::Registry.expects(:process).once
      send_webhook "order_update", { foo: :bar }, use_new_headers: true
      assert_response :ok
    end

    test "receives webhook with legacy header format and calls process" do
      ShopifyAPI::Webhooks::Registry.stubs(:process).returns(nil)
      ShopifyAPI::Webhooks::Registry.expects(:process).once
      send_webhook "order_update", { foo: :bar }, use_new_headers: false
      assert_response :ok
    end

    private

    def send_webhook(name, data, use_new_headers: false)
      post(
        shopify_app.webhooks_path(name),
        params: data,
        headers: headers(name, use_new_headers: use_new_headers),
      )
    end

    def headers(name, use_new_headers: false)
      hmac = OpenSSL::HMAC.digest(
        OpenSSL::Digest.new("sha256"),
        "API_SECRET_KEY",
        "{}",
      )
      if use_new_headers
        {
          "shopify-topic" => name,
          "shopify-hmac-sha256" => Base64.encode64(hmac),
          "shopify-shop-domain" => "test.myshopify.com",
        }
      else
        {
          "x-shopify-topic" => name,
          "x-shopify-hmac-sha256" => Base64.encode64(hmac),
          "x-shopify-shop-domain" => "test.myshopify.com",
        }
      end
    end
  end
end
