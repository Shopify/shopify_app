# frozen_string_literal: true

require "test_helper"

module Shopify
  class AfterAuthenticateJob < ActiveJob::Base
    def perform; end
  end
end

class CartsUpdateJob < ActiveJob::Base
  extend ShopifyAPI::Webhooks::Handler

  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic: topic, shop_domain: shop, webhook: body)
    end
  end

  def perform; end
end

class PostAuthenticateTasksTest < ActiveSupport::TestCase
  SHOP_DOMAIN = "shop.myshopify.io"

  setup do
    ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
    ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryShopSessionStore
    ShopifyAppConfigurer.setup_context

    @offline_session = ShopifyAPI::Auth::Session.new(shop: SHOP_DOMAIN, access_token: "offline_token")
    @online_session = ShopifyAPI::Auth::Session.new(shop: SHOP_DOMAIN, access_token: "online_token", is_online: true)

    ShopifyApp::SessionRepository.store_shop_session(@offline_session)
  end

  test "#perform runs WebhooksManager job if webhooks are configured" do
    ShopifyApp.configure do |config|
      config.webhooks = [{ topic: "carts/update", address: "example-app.com/webhooks" }]
    end

    ShopifyApp::WebhooksManager.expects(:queue).with(SHOP_DOMAIN, "offline_token")

    ShopifyApp::Auth::PostAuthenticateTasks.perform(@offline_session)
  end

  test "#perform doesn't run the WebhooksManager if no webhooks are configured" do
    ShopifyApp.configure do |config|
      config.webhooks = []
    end
    ShopifyApp::WebhooksManager.add_registrations

    ShopifyApp::WebhooksManager.expects(:queue).never

    ShopifyApp::Auth::PostAuthenticateTasks.perform(@offline_session)
  end

  test "#perform triggers install_webhook job with an offline session after an online session OAuth" do
    ShopifyApp.configure do |config|
      config.webhooks = [{ topic: "carts/update", address: "example-app.com/webhooks" }]
    end
    ShopifyApp::WebhooksManager.expects(:queue).with(SHOP_DOMAIN, "offline_token")

    ShopifyApp::Auth::PostAuthenticateTasks.perform(@online_session)
  ensure
    ShopifyApp::SessionRepository.shop_storage.clear
  end

  test "#perform calls AfterAuthenticateJob and performs inline when inline is true" do
    ShopifyApp.configure do |config|
      config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: true }
    end

    Shopify::AfterAuthenticateJob.expects(:perform_now).with(shop_domain: SHOP_DOMAIN)

    ShopifyApp::Auth::PostAuthenticateTasks.perform(@offline_session)
  end

  test "#perform calls AfterAuthenticateJob and performs asynchronous when inline isn't true" do
    ShopifyApp.configure do |config|
      config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: false }
    end

    Shopify::AfterAuthenticateJob.expects(:perform_later).with(shop_domain: SHOP_DOMAIN)

    ShopifyApp::Auth::PostAuthenticateTasks.perform(@offline_session)
  end

  test "#perform doesn't call AfterAuthenticateJob if job is nil" do
    ShopifyApp.configure do |config|
      config.after_authenticate_job = { job: nil, inline: false }
    end

    Shopify::AfterAuthenticateJob.expects(:perform_later).never

    ShopifyApp::Auth::PostAuthenticateTasks.perform(@offline_session)
  end

  test "#perform calls AfterAuthenticateJob and performs async if inline isn't present" do
    ShopifyApp.configure do |config|
      config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob }
    end

    Shopify::AfterAuthenticateJob.expects(:perform_later).with(shop_domain: SHOP_DOMAIN)

    ShopifyApp::Auth::PostAuthenticateTasks.perform(@offline_session)
  end

  test "#perform calls AfterAuthenticateJob constantizes from a string to a class" do
    ShopifyApp.configure do |config|
      config.after_authenticate_job = { job: "Shopify::AfterAuthenticateJob", inline: false }
    end

    Shopify::AfterAuthenticateJob.expects(:perform_later).with(shop_domain: SHOP_DOMAIN)

    ShopifyApp::Auth::PostAuthenticateTasks.perform(@offline_session)
  end

  test "#perform calls AfterAuthenticateJob raises if the string is not a valid job class" do
    ShopifyApp.configure do |config|
      config.after_authenticate_job = { job: "InvalidJobClassThatDoesNotExist", inline: false }
    end

    assert_raise NameError do
      ShopifyApp::Auth::PostAuthenticateTasks.perform(@offline_session)
    end
  end
end
