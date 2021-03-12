# frozen_string_literal: true
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
    # TODO: drop `rubocop:todo Style/RedundantBegin` together with Ruby 2.4 support
    #   As this style is supported since Ruby 2.5 (see https://bugs.ruby-lang.org/issues/12906)
    begin # rubocop:todo Style/RedundantBegin
      original_root = ShopifyApp.configuration.root_url

      ShopifyApp.configure do |config|
        config.root_url = "/nested"
      end

      assert_equal("/nested/login", ShopifyApp.configuration.login_url)
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
    webhook = { topic: 'carts/update', address: 'example-app.com/webhooks', format: 'json' }

    ShopifyApp.configure do |config|
      config.webhooks = [webhook]
    end

    assert_equal webhook, ShopifyApp.configuration.webhooks.first
  end

  test "has_webhooks? is true if webhooks have been configured" do
    refute ShopifyApp.configuration.has_webhooks?

    ShopifyApp.configure do |config|
      config.webhooks = [{ topic: 'carts/update', address: 'example-app.com/webhooks', format: 'json' }]
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

  test "can set shop_session_repository with a string" do
    ShopifyApp.configure do |config|
      config.shop_session_repository = 'ShopifyApp::InMemoryShopSessionStore'
    end

    assert_equal ShopifyApp::InMemoryShopSessionStore, ShopifyApp.configuration.shop_session_repository
    assert_equal ShopifyApp::InMemoryShopSessionStore, ShopifyApp::SessionRepository.shop_storage
  end

  test "can set shop_session_repository with a class" do
    ShopifyApp.configure do |config|
      config.shop_session_repository = ShopifyApp::InMemoryShopSessionStore
    end

    assert_equal ShopifyApp::InMemoryShopSessionStore, ShopifyApp.configuration.shop_session_repository
    assert_equal ShopifyApp::InMemoryShopSessionStore, ShopifyApp::SessionRepository.shop_storage
  end

  test "can set user_session_repository with a string" do
    ShopifyApp.configure do |config|
      config.user_session_repository = 'ShopifyApp::InMemoryUserSessionStore'
    end

    assert_equal ShopifyApp::InMemoryUserSessionStore, ShopifyApp.configuration.user_session_repository
    assert_equal ShopifyApp::InMemoryUserSessionStore, ShopifyApp::SessionRepository.user_storage
  end

  test "can set user_session_repository with a class" do
    ShopifyApp.configure do |config|
      config.user_session_repository = ShopifyApp::InMemoryUserSessionStore
    end

    assert_equal ShopifyApp::InMemoryUserSessionStore, ShopifyApp.configuration.user_session_repository
    assert_equal ShopifyApp::InMemoryUserSessionStore, ShopifyApp::SessionRepository.user_storage
  end

  test "enable_same_site_none is false in tests" do
    ShopifyApp.configure do |config|
      config.embedded_app = true
      config.enable_same_site_none = true
    end

    refute ShopifyApp.configuration.enable_same_site_none
  end

  test "enable_same_site_none is true if embedded and enable_same_site_none is nil" do
    ShopifyApp.configure do |config|
      config.embedded_app = true
    end

    Rails.env.expects(:test?).returns(false)
    assert ShopifyApp.configuration.enable_same_site_none
  end

  test "enable_same_site_none is false if embedded and enable_same_site_none is false" do
    ShopifyApp.configure do |config|
      config.embedded_app = true
      config.enable_same_site_none = false
    end

    Rails.env.expects(:test?).returns(false)
    refute ShopifyApp.configuration.enable_same_site_none
  end

  test "enable_same_site_none is false if not embedded and enable_same_site_none is nil" do
    ShopifyApp.configure do |config|
      config.embedded_app = false
    end

    Rails.env.expects(:test?).returns(false)
    refute ShopifyApp.configuration.enable_same_site_none
  end

  test "enable_same_site_none is true if not embedded and enable_same_site_none is true" do
    ShopifyApp.configure do |config|
      config.embedded_app = false
      config.enable_same_site_none = true
    end

    Rails.env.expects(:test?).returns(false)
    assert ShopifyApp.configuration.enable_same_site_none
  end

  test "user_access_scopes resolves to scope if user_access_scopes are undefined" do
    ShopifyApp.configure do |config|
      config.scope = 'read_products'
    end

    assert_equal ShopifyApp.configuration.scope, ShopifyApp.configuration.user_access_scopes
  end

  test "shop_access_scopes resolves to scope if shop_access_scopes are undefined" do
    ShopifyApp.configure do |config|
      config.scope = 'write_orders'
    end

    assert_equal ShopifyApp.configuration.scope, ShopifyApp.configuration.shop_access_scopes
  end

  test "shop_access_scopes are set correctly" do
    ShopifyApp.configure do |config|
      config.scope = 'write_orders'
      config.shop_access_scopes = 'read_orders'
    end

    assert_equal ShopifyApp.configuration.shop_access_scopes, 'read_orders'
    assert_equal ShopifyApp.configuration.scope, 'write_orders'
  end

  test "user_access_scopes are set correctly" do
    ShopifyApp.configure do |config|
      config.scope = 'write_orders'
      config.user_access_scopes = 'read_orders'
    end

    assert_equal ShopifyApp.configuration.user_access_scopes, 'read_orders'
    assert_equal ShopifyApp.configuration.scope, 'write_orders'
  end

  test "noop access scope strategies defined when reauth_on_access_scope_changes is false" do
    ShopifyApp.configure do |config|
      config.reauth_on_access_scope_changes = false
    end

    assert_equal ShopifyApp::AccessScopes::NoopStrategy, ShopifyApp.configuration.shop_access_scopes_strategy
    assert_equal ShopifyApp::AccessScopes::NoopStrategy, ShopifyApp.configuration.user_access_scopes_strategy
  end

  test "shop and user access scope strategies defined when reauth_on_access_scope_changes is true" do
    ShopifyApp.configure do |config|
      config.reauth_on_access_scope_changes = true
    end

    assert_equal ShopifyApp::AccessScopes::ShopStrategy, ShopifyApp.configuration.shop_access_scopes_strategy
    assert_equal ShopifyApp::AccessScopes::UserStrategy, ShopifyApp.configuration.user_access_scopes_strategy
  end
end
