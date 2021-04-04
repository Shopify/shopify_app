# frozen_string_literal: true
require 'test_helper'

class ShopifyApp::WebhooksManagerGraphqlTest < ActiveSupport::TestCase
  setup do
    @site = 'https://this-is-my-test-shop.myshopify.com'
    ShopifyAPI::Base.api_version = '2021-01'
    ShopifyAPI::Base.site = @site
    ShopifyAPI::GraphQL.schema_location = Pathname('test/fixtures/graphql')
    ShopifyAPI::GraphQL.initialize_clients
    @graphql_path = @site + ShopifyAPI::ApiVersion.new('2021-01').construct_graphql_path
    @client = ShopifyAPI::GraphQL.client

    @webhooks = [
      { topic: 'app/uninstalled', address: "https://example-app.com/webhooks/app_uninstalled" },
      { topic: 'orders/create', address: "https://example-app.com/webhooks/order_create" },
      { topic: 'orders/updated', address: "https://example-app.com/webhooks/order_updated" },
    ]

    @manager = ShopifyApp::WebhooksManager.new(@webhooks, adapter: ShopifyApp::Webhooks::GraphqlAdapter)
  end

  test "#create_webhooks makes calls to create webhooks" do
    current_webhooks_stub = stub_current_webhooks([])

    creation_stub1 = stub_webhook_creation('APP_UNINSTALLED', "https://example-app.com/webhooks/app_uninstalled")
    creation_stub2 = stub_webhook_creation('ORDERS_CREATE', "https://example-app.com/webhooks/order_create")
    creation_stub3 = stub_webhook_creation('ORDERS_UPDATED', "https://example-app.com/webhooks/order_updated")

    @manager.create_webhooks

    assert_requested current_webhooks_stub
    assert_requested creation_stub1
    assert_requested creation_stub2
    assert_requested creation_stub3
  end

  test "#create_webhooks when creating a webhook fails, raises an error" do
    stub_current_webhooks([])
    errors = [{ message: 'topic already taken' }]
    stub_webhook_creation('APP_UNINSTALLED', "https://example-app.com/webhooks/app_uninstalled", errors)

    e = assert_raise ShopifyApp::WebhooksManager::CreationFailed do
      @manager.create_webhooks
    end

    assert_equal 'topic already taken', e.message
  end

  test "#create_webhooks doesn't create webhooks that are already created" do
    current_webhooks_stub = stub_current_webhooks([
      {
        "node": {
          "topic": "APP_UNINSTALLED", "endpoint": { "callbackUrl": "https://example-app.com/webhooks/app_uninstalled" }
        },
      },
      {
        "node": {
          "topic": "ORDERS_CREATE", "endpoint": { "callbackUrl": "https://example-app.com/webhooks/order_create" }
        },
      },
      {
        "node": {
          "topic": "ORDERS_UPDATED", "endpoint": { "callbackUrl": "https://example-app.com/webhooks/order_updated" }
        },
      },
    ])

    creation_stub1 = stub_webhook_creation('APP_UNINSTALLED', "https://example-app.com/webhooks/app_uninstalled")
    creation_stub2 = stub_webhook_creation('ORDERS_CREATE', "https://example-app.com/webhooks/order_create")
    creation_stub3 = stub_webhook_creation('ORDERS_UPDATED', "https://example-app.com/webhooks/order_updated")

    assert_nothing_raised { @manager.create_webhooks }

    assert_requested current_webhooks_stub
    assert_not_requested creation_stub1
    assert_not_requested creation_stub2
    assert_not_requested creation_stub3
  end

  test "#recreate_webhooks! destroys all webhooks and recreates" do
    @manager.expects(:destroy_webhooks)
    @manager.expects(:create_webhooks)

    @manager.recreate_webhooks!
  end

  test "#destroy_webhooks doesnt freak out if there are no webhooks" do
    stub_current_webhooks([])

    @manager.destroy_webhooks
  end

  test "#destroy_webhooks makes calls to destroy webhooks" do
    current_webhooks_stub = stub_current_webhooks([
      {
        "node": {
          "id": "APP_UNINSTALLED_WEBHOOK",
          "topic": "APP_UNINSTALLED",
          "endpoint": { "callbackUrl": "https://example-app.com/webhooks/app_uninstalled" },
        },
      },
      {
        "node": {
          "id": "ORDERS_CREATE_WEBHOOK",
          "topic": "ORDERS_CREATE",
          "endpoint": { "callbackUrl": "https://example-app.com/webhooks/order_create" },
        },
      },
      {
        "node": {
          "id": "ORDERS_UPDATED_WEBHOOK",
          "topic": "ORDERS_UPDATED",
          "endpoint": { "callbackUrl": "https://example-app.com/webhooks/order_updated" },
        },
      },
    ])

    webhook_deletion_stub1 = stub_webhook_deletion('APP_UNINSTALLED_WEBHOOK')
    webhook_deletion_stub2 = stub_webhook_deletion('ORDERS_CREATE_WEBHOOK')
    webhook_deletion_stub3 = stub_webhook_deletion('ORDERS_UPDATED_WEBHOOK')

    @manager.destroy_webhooks

    assert_requested current_webhooks_stub
    assert_requested webhook_deletion_stub1
    assert_requested webhook_deletion_stub2
    assert_requested webhook_deletion_stub3
  end

  test "#destroy_webhooks does not destroy webhooks that do not have a matching address" do
    current_webhooks_stub = stub_current_webhooks([
      {
        "node": {
          "id": "NON_EXISTING_WEBHOOK",
          "topic": "PRODUCT_UPDATE",
          "endpoint": { "callbackUrl": "https://example-app.com/webhooks/product_update" },
        },
      },
    ])
    webhook_deletion_stub = stub_webhook_deletion('NON_EXISTING_WEBHOOK')

    @manager.destroy_webhooks

    assert_requested current_webhooks_stub
    assert_not_requested webhook_deletion_stub
  end

  private

  def stub_current_webhooks(result)
    stub_request(:post, @graphql_path)
      .with(body: /webhookSubscriptions\(first: 250\)/)
      .to_return(body: { data: { webhookSubscriptions: { edges: result } } }.to_json)
  end

  def stub_webhook_creation(topic, address, errors = [])
    result = { webhookSubscription: {}, userErrors: errors }
    stub_request(:post, @graphql_path)
      .with(body: /webhookSubscriptionCreate.*#{topic}.*#{address}/)
      .to_return(body: { data: { webhookSubscriptionCreate: result } }.to_json)
  end

  def stub_webhook_deletion(id)
    result = { deletedWebhookSubscriptionId: id, userErrors: [] }
    stub_request(:post, @graphql_path)
      .with(body: /webhookSubscriptionDelete.*#{id}/)
      .to_return(body: { data: { webhookSubscriptionDelete: result } }.to_json)
  end
end
