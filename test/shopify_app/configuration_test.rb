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
      config.after_authenticate_job = false
    end

    assert_equal true, ShopifyApp.configuration.embedded_app
    assert_equal false, ShopifyApp.configuration.after_authenticate_job
  end

  test "defaults login_url" do
    assert_equal "/login", ShopifyApp.configuration.login_url
  end

  test "can set root_url which affects login_url" do
    begin
      original_root = ShopifyApp.configuration.root_url

      ShopifyApp.configure do |config|
        config.root_url = "/nested"
      end

      assert_equal "/nested/login", ShopifyApp.configuration.login_url
    ensure
      ShopifyApp.configuration.root_url = original_root
    end
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
    ShopifyApp.configuration = nil

    assert_equal :'custom-queue-name', ShopifyApp.configuration.webhooks_manager_queue_name
    assert_equal :'custom-queue-name', ShopifyApp.configuration.scripttags_manager_queue_name
  end

  test "webhooks_manager_queue_name and scripttags_manager_queue_name are nil if not configured and ActiveJob queue_name is nil (activeJob overrides a nil queue_name to default)" do
    Rails.application.config.active_job.stubs(:queue_name).returns(:default)
    ShopifyApp.configuration = nil

    assert_equal :default, ShopifyApp.configuration.webhooks_manager_queue_name
    assert_equal :default, ShopifyApp.configuration.scripttags_manager_queue_name
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

  test "webhook_jobs_namespace handles default" do
    assert_equal "TestJob", ShopifyApp::WebhooksController.new.send(:webhook_job_klass_name, 'test')
  end

  test "webhook_jobs_namespace handles single plural value" do
    ShopifyApp.configure do |config|
      config.webhook_jobs_namespace = 'webhooks'
    end

    assert_equal "Webhooks::TestJob", ShopifyApp::WebhooksController.new.send(:webhook_job_klass_name, 'test')
  end

  test "webhook_jobs_namespace handles nested values" do
    ShopifyApp.configure do |config|
      config.webhook_jobs_namespace = 'shopify/webhooks'
    end

    assert_equal "Shopify::Webhooks::TestJob", ShopifyApp::WebhooksController.new.send(:webhook_job_klass_name, 'test')
  end

  test "can set session_repository with a string" do
    ShopifyApp.configure do |config|
      config.session_repository = 'ShopifyApp::InMemorySessionStore'
    end

    assert_equal 'ShopifyApp::InMemorySessionStore', ShopifyApp.configuration.session_repository
    assert_equal ShopifyApp::InMemorySessionStore, ShopifyApp::SessionRepository.storage
  end

  test "can set session_repository with a class" do
    ShopifyApp.configure do |config|
      config.session_repository = ShopifyApp::InMemorySessionStore
    end

    assert_equal ShopifyApp::InMemorySessionStore, ShopifyApp.configuration.session_repository
    assert_equal ShopifyApp::InMemorySessionStore, ShopifyApp::SessionRepository.storage
  end
end
