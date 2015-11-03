require 'test_helper'

class ShopifyApp::WebhooksManagerTest < ActiveSupport::TestCase

  setup do
    ShopifyApp.configure do |config|
      config.webhooks = [
        {topic: 'app/uninstalled', address: "https://example-app.com/webhooks/app_uninstalled", format: 'json'},
        {topic: 'orders/create', address: "https://example-app.com/webhooks/order_create", format: 'json'},
        {topic: 'orders/updated', address: "https://example-app.com/webhooks/order_updated", format: 'json'},
      ]
    end

    @manager = ShopifyApp::WebhooksManager.new("regular-shop.myshopify.com", "token")
  end

  test "#create_webhooks makes calls to create webhooks" do
    ShopifyAPI::Webhook.stubs(all: [])

    expect_webhook_creation('app/uninstalled', "https://example-app.com/webhooks/app_uninstalled")
    expect_webhook_creation('orders/create', "https://example-app.com/webhooks/order_create")
    expect_webhook_creation('orders/updated', "https://example-app.com/webhooks/order_updated")

    @manager.create_webhooks
  end

  test "#create_webhooks when creating a webhook fails, raises an error" do
    ShopifyAPI::Webhook.stubs(all: [])
    webhook = stub(persisted?: false)
    ShopifyAPI::Webhook.stubs(create: webhook)

    assert_raise ShopifyApp::WebhooksManager::CreationFailed do
      @manager.create_webhooks
    end
  end

  test "#create_webhooks when creating a webhook fails and the webhook exists, do not raise an error" do
    webhook = stub(persisted?: false)
    webhooks = all_webhook_topics.map{|t| stub(topic: t)}
    ShopifyAPI::Webhook.stubs(create: webhook, all: webhooks)

    assert_nothing_raised ShopifyApp::WebhooksManager::CreationFailed do
      @manager.create_webhooks
    end
  end

  test "#recreate_webhooks! destroys all webhooks and recreates" do
    @manager.expects(:destroy_webhooks)
    @manager.expects(:create_webhooks)

    @manager.recreate_webhooks!
  end

  test "#destroy_webhooks makes calls to destroy webhooks" do
    ShopifyAPI::Webhook.stubs(:all).returns(Array.wrap(all_mock_webhooks.first))
    ShopifyAPI::Webhook.expects(:delete).with(all_mock_webhooks.first.id)

    @manager.destroy_webhooks
  end

  test "#destroy_webhooks does not destroy webhooks that do not have a matching address" do
    ShopifyAPI::Webhook.stubs(:all).returns([stub(address: 'http://something-or-the-other.com/webhooks/product_update', id: 7214109)])
    ShopifyAPI::Webhook.expects(:delete).never

    @manager.destroy_webhooks
  end

  private

  def expect_webhook_creation(topic, address)
    stub_webhook = stub(persisted?: true)
    ShopifyAPI::Webhook.expects(:create).with(topic: topic, address: address, format: 'json').returns(stub_webhook)
  end

  def all_webhook_topics
    @webhooks ||= ['app/uninstalled', 'orders/create', 'orders/updated']
  end

  def all_mock_webhooks
    [
      stub(id: 1, address: "https://example-app.com/webhooks/app_uninstalled", topic: 'app/uninstalled'),
      stub(id: 2, address: "https://example-app.com/webhooks/order_create", topic: 'orders/create'),
      stub(id: 3, address: "https://example-app.com/webhooks/order_updated", topic: 'orders/updated'),
    ]
  end
end
