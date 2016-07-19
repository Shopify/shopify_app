require 'test_helper'

class ConfigurationTest < ActiveSupport::TestCase

  setup do
    ShopifyApp.configuration = nil
  end

  teardown do
    Rails.application.config.active_job.queue_name = nil
  end

  test "configure" do
    ShopifyApp.configure do |config|
      config.embedded_app = true
    end

    assert_equal true, ShopifyApp.configuration.embedded_app
  end

  test "defaults to myshopify_domain" do
    assert_equal "myshopify.com", ShopifyApp.configuration.myshopify_domain
  end

  test "can set myshopify_domain" do
    ShopifyApp.configure do |config|
      config.myshopify_domain = 'myshopify.io'
    end

    assert_equal "myshopify.io", ShopifyApp.configuration.myshopify_domain
  end

  test "can configure webhooks for creation" do
    webhook = {topic: 'carts/update', address: 'example-app.com/webhooks', format: 'json'}

    ShopifyApp.configure do |config|
      config.webhooks = [webhook]
    end

    assert_equal webhook, ShopifyApp.configuration.webhooks.first
  end

  test "has_webhooks? is true if webhooks have been configured" do
    refute ShopifyApp.configuration.has_webhooks?

    ShopifyApp.configure do |config|
      config.webhooks = [{topic: 'carts/update', address: 'example-app.com/webhooks', format: 'json'}]
    end

    assert ShopifyApp.configuration.has_webhooks?
  end

  test "webhooks_manager_queue_name and scripttags_manager_queue_name are equal to ActiveJob queue_name if not configured" do
    Rails.application.config.active_job.queue_name = :'custom-queue-name'

    assert_equal :'custom-queue-name', ShopifyApp.configuration.webhooks_manager_queue_name
    assert_equal :'custom-queue-name', ShopifyApp.configuration.scripttags_manager_queue_name
  end

  test "webhooks_manager_queue_name and scripttags_manager_queue_name are nil if not configured and ActiveJob queue_name is nil" do
    Rails.application.config.active_job.stubs(:queue_name).returns(nil)

    assert_equal nil, ShopifyApp.configuration.webhooks_manager_queue_name
    assert_equal nil, ShopifyApp.configuration.scripttags_manager_queue_name
  end

  test "can override queue names" do
    Rails.application.config.active_job.queue_name = :'custom-queue-name'
    ShopifyApp.configure do |config|
      config.webhooks_manager_queue_name = :'my-custom-worker-1'
      config.scripttags_manager_queue_name = :'my-custom-worker-2'
    end

    assert_equal :'my-custom-worker-1', ShopifyApp.configuration.webhooks_manager_queue_name
    assert_equal :'my-custom-worker-2', ShopifyApp.configuration.scripttags_manager_queue_name
  end

end
