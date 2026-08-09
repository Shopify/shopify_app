# frozen_string_literal: true

require_relative "../../test_helper"

class OrdersUpdatedJob < ActiveJob::Base
  extend ShopifyAPI::Webhooks::WebhookHandler

  def self.handle(data:)
    perform_later(topic: data.topic, shop_domain: data.shop, webhook: data.body)
  end

  def perform; end
end

class ShopifyApp::WebhooksManagerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#add_registrations makes calls to library's add_registration" do
    expected_hash = {
      topic: "orders/updated",
      delivery_method: :http,
      path: "webhooks/orders_updated",
      handler: OrdersUpdatedJob,
      fields: nil,
      metafield_namespaces: nil,
      filter: nil,
    }

    ShopifyAPI::Webhooks::Registry.expects(:add_registration).with(**expected_hash).once
    ShopifyApp.configure do |config|
      config.webhooks = [
        { topic: "orders/updated", path: "webhooks/orders_updated" },
      ]
    end
    ShopifyApp::WebhooksManager.add_registrations
  end

  test "#add_registrations deduces path from address" do
    expected_hash = {
      topic: "orders/updated",
      delivery_method: :http,
      path: "/webhooks/orders_updated",
      handler: OrdersUpdatedJob,
      fields: nil,
      metafield_namespaces: nil,
      filter: nil,
    }

    ShopifyAPI::Webhooks::Registry.expects(:add_registration).with(**expected_hash).once
    ShopifyApp.configure do |config|
      config.webhooks = [
        {
          topic: "orders/updated",
          address: "https://some.domain.over.the.rainbow.com/webhooks/orders_updated",
        },
      ]
    end

    ShopifyApp::WebhooksManager.add_registrations
  end

  test "#add_registrations includes filters" do
    expected_hash = {
      topic: "orders/updated",
      delivery_method: :http,
      path: "/webhooks/orders_updated",
      handler: OrdersUpdatedJob,
      fields: nil,
      metafield_namespaces: nil,
      filter: "id:*",
    }

    ShopifyAPI::Webhooks::Registry.expects(:add_registration).with(**expected_hash).once
    ShopifyApp.configure do |config|
      config.webhooks = [
        {
          topic: "orders/updated",
          address: "https://some.domain.over.the.rainbow.com/webhooks/orders_updated",
          filter: "id:*",
        },
      ]
    end

    ShopifyApp::WebhooksManager.add_registrations
  end

  test "#add_registrations raises an error when missing path and address" do
    ShopifyApp.configure do |config|
      config.webhooks = [
        {
          topic: "orders/updated",
        },
      ]
    end

    assert_raises ::ShopifyApp::MissingWebhookJobError do
      ShopifyApp::WebhooksManager.add_registrations
    end
  end

  test "#add_registrations does not makes calls to library's add_registration when there are no webhooks" do
    ShopifyAPI::Webhooks::Registry.expects(:add_registration).never
    ShopifyApp.configure do |config|
      config.webhooks = []
    end
    ShopifyApp::WebhooksManager.add_registrations
  end

  test "#recreate_webhooks! destroys all webhooks and recreates" do
    ShopifyApp.configuration.expects(:has_webhooks?).returns(true)
    session = ShopifyAPI::Auth::Session.new(shop: "shop.myshopify.com")

    ShopifyApp::WebhooksManager.expects(:destroy_webhooks)
    ShopifyApp::WebhooksManager.expects(:add_registrations)
    ShopifyApp::WebhooksManager.expects(:create_webhooks).with(session: session)

    ShopifyApp::WebhooksManager.recreate_webhooks!(session: session)
  end

  test "#destroy_webhooks destroy all webhooks" do
    session = ShopifyAPI::Auth::Session.new(shop: "shop.myshopify.com")
    ShopifyAPI::Webhooks::Registry.expects(:unregister).with(topic: "orders/updated", session: session)

    ShopifyApp.configure do |config|
      config.webhooks = [
        { topic: "orders/updated", path: "webhooks" },
      ]
    end
    ShopifyApp::WebhooksManager.destroy_webhooks(session: session)
  end

  test "#destroy_webhooks does not call unregister if there is no webhook" do
    ShopifyAPI::Webhooks::Registry.expects(:unregister).never

    ShopifyApp.configure do |config|
      config.webhooks = []
    end
    ShopifyApp::WebhooksManager.destroy_webhooks(session: ShopifyAPI::Auth::Session.new(shop: "shop.myshopify.com"))
  end

  test "#add_registrations registers a job that the shopify_api library can dispatch to" do
    ShopifyAPI::Webhooks::Registry.clear

    ShopifyApp.configure do |config|
      config.webhooks = [
        { topic: "orders/updated", path: "webhooks/orders_updated" },
      ]
    end

    ShopifyApp::WebhooksManager.add_registrations

    body = { "foo" => "bar" }.to_json

    assert_enqueued_with(
      job: OrdersUpdatedJob,
      args: [{ topic: "orders/updated", shop_domain: "test.myshopify.com", webhook: { "foo" => "bar" } }],
    ) do
      ShopifyAPI::Webhooks::Registry.process(webhook_request(body))
    end
  end

  private

  def webhook_request(body)
    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), ShopifyApp.configuration.secret, body)
    ShopifyAPI::Webhooks::Request.new(
      raw_body: body,
      headers: {
        "x-shopify-topic" => "orders/updated",
        "x-shopify-hmac-sha256" => Base64.encode64(hmac),
        "x-shopify-shop-domain" => "test.myshopify.com",
        "x-shopify-api-version" => TEST_API_VERSION,
        "x-shopify-webhook-id" => "12345",
      },
    )
  end
end
