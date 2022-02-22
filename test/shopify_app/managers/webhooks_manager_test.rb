# frozen_string_literal: true
require 'test_helper'

class OrdersUpdatedJob < ActiveJob::Base
  extend ShopifyAPI::Webhooks::Handler

  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic: topic, shop_domain: shop, webhook: body)
    end
  end

  def perform; end
end

class ShopifyApp::WebhooksManagerTest < ActiveSupport::TestCase

  test "#add_registrations makes calls to library's add_registration" do
    ShopifyAPI::Webhooks::Registry.expects(:add_registration).once
    ShopifyApp.configure do |config|
      config.webhooks = [
        { topic: "orders/updated", address: "/webhooks" },
      ]
    end
    ShopifyApp::WebhooksManager.add_registrations
  end

  test "#add_registrations does not makes calls to library's add_registration when there is no webhooks" do
    ShopifyAPI::Webhooks::Registry.expects(:add_registration).never
    ShopifyApp.configure do |config|
      config.webhooks = []
    end
    ShopifyApp::WebhooksManager.add_registrations
  end

  test "#recreate_webhooks! destroys all webhooks and recreates" do
    ShopifyAPI::Webhooks::Registry.expects(:register_all).with(session: ShopifyAPI::Context.active_session)
    ShopifyAPI::Webhooks::Registry.expects(:unregister).with(topic: "orders/updated", session: ShopifyAPI::Context.active_session)
    ShopifyApp::WebhooksManager.expects(:add_registrations).twice

    ShopifyApp.configure do |config|
      config.webhooks = [
        { topic: "orders/updated", address: "/webhooks" },
      ]
    end
    ShopifyApp::WebhooksManager.add_registrations
    ShopifyApp::WebhooksManager.recreate_webhooks!
  end

  test "#recreate_webhooks! does not call unregister if there is no webhook" do
    ShopifyAPI::Webhooks::Registry.expects(:register_all).never
    ShopifyAPI::Webhooks::Registry.expects(:unregister).never
    ShopifyAPI::Webhooks::Registry.expects(:add_registration).never

    ShopifyApp.configure do |config|
      config.webhooks = [
      ]
    end
    ShopifyApp::WebhooksManager.add_registrations
    ShopifyApp::WebhooksManager.recreate_webhooks!
  end
end
