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

module ShopifyApp
  class CallbackControllerTest < ActionController::TestCase
    setup do
      @routes = ShopifyApp::Engine.routes
      ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
      ShopifyApp::SessionRepository.user_storage = nil
      ShopifyAppConfigurer.setup_context
      I18n.locale = :en

      request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6)"\
        "AppleWebKit/537.36 (KHTML, like Gecko)"\
        "Chrome/69.0.3497.100 Safari/537.36"
    end

    test "#callback flashes error when omniauth is not present" do
      get :callback,
        params: { shop: "shop", code: "code", state: "state", timestamp: "timestamp", host: "host", hmac: "hmac" }
      assert_equal flash[:error], "Could not log in to Shopify store"
    end

    test "#callback flashes error in Spanish" do
      I18n.locale = :es
      get :callback,
        params: { shop: "shop", code: "code", state: "state", timestamp: "timestamp", host: "host", hmac: "hmac" }
      assert_match "sesión", flash[:error]
    end

    test "#callback rescued errors of ShopifyAPI::Error will not emit a deprecation notice" do
      ShopifyAPI::Auth::Oauth.expects(:validate_auth_callback).raises(ShopifyAPI::Errors::MissingRequiredArgumentError)
      assert_not_deprecated do
        get :callback,
          params: { shop: "shop", code: "code", state: "state", timestamp: "timestamp", host: "host", hmac: "hmac" }
      end
      assert_equal flash[:error], "Could not log in to Shopify store"
    end

    test "#callback rescued errors other than ShopifyAPI::Error will emit a deprecation notice" do
      parent_deprecation_setting = ActiveSupport::Deprecation.silenced
      ActiveSupport::Deprecation.silenced = false
      ShopifyAPI::Auth::Oauth.expects(:validate_auth_callback).raises(StandardError)
      assert_deprecated(/An error of type StandardError was rescued/) do
        get :callback,
          params: { shop: "shop", code: "code", state: "state", timestamp: "timestamp", host: "host", hmac: "hmac" }
      end
      assert_equal flash[:error], "Could not log in to Shopify store"
      ActiveSupport::Deprecation.silenced = parent_deprecation_setting
    end

    test "#callback calls ShopifyAPI::Auth::Oauth.validate_auth_callback" do
      mock_oauth

      get :callback, params: @callback_params
    end

    test "#callback starts the WebhooksManager if webhooks are configured" do
      ShopifyApp.configure do |config|
        config.webhooks = [{ topic: "carts/update", address: "example-app.com/webhooks" }]
      end

      ShopifyApp::WebhooksManager.expects(:queue).with("shop", "token")

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback doesn't run the WebhooksManager if no webhooks are configured" do
      ShopifyApp.configure do |config|
        config.webhooks = []
      end
      ShopifyApp::WebhooksManager.add_registrations

      ShopifyApp::WebhooksManager.expects(:queue).never

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback calls #perform_after_authenticate_job and performs inline when inline is true" do
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: true }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_now).with(shop_domain: "shop")

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback calls #perform_after_authenticate_job and performs asynchronous when inline isn't true" do
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: false }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_later).with(shop_domain: "shop")

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback doesn't call #perform_after_authenticate_job if job is nil" do
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: nil, inline: false }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_later).never

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback calls #perform_after_authenticate_job and performs async if inline isn't present" do
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_later).with(shop_domain: "shop")

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback calls #perform_after_authenticate_job constantizes from a string to a class" do
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: "Shopify::AfterAuthenticateJob", inline: false }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_later).with(shop_domain: "shop")

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback calls #perform_after_authenticate_job raises if the string is not a valid job class" do
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: "InvalidJobClassThatDoesNotExist", inline: false }
      end

      mock_oauth

      assert_raise NameError do
        get :callback, params: @callback_params
      end
    end

    test "#callback redirects to the root_url with shop and host parameter for non-embedded" do
      ShopifyApp.configuration.embedded_app = false
      ShopifyAppConfigurer.setup_context # to reset the context, as there's no attr_writer for embedded
      mock_oauth

      get :callback, params: @callback_params # host is required for App Bridge 2.0

      assert_redirected_to "/?host=#{@callback_params[:host]}&shop=#{@callback_params[:shop]}.myshopify.com"
    end

    test "#callback redirects to the embedded app url for embedded" do
      mock_oauth

      get :callback, params: @callback_params # host is required for App Bridge 2.0

      assert_redirected_to "https://test.host/admin/apps/key"
    end

    test "#callback performs install_webhook job after authentication" do
      mock_oauth

      ShopifyApp.configure do |config|
        config.webhooks = [{ topic: "carts/update", address: "example-app.com/webhooks" }]
      end

      ShopifyApp::WebhooksManager.expects(:queue).with("shop", "token")

      get :callback, params: @callback_params
      assert_response 302
    end

    test "#callback performs install_scripttags job after authentication" do
      mock_oauth

      ShopifyApp.configure do |config|
        config.scripttags = [{ event: "onload", src: "https://example.com/fancy.js" }]
      end

      ShopifyApp::ScripttagsManager.expects(:queue).with("shop", "token", ShopifyApp.configuration.scripttags)

      get :callback, params: @callback_params
      assert_response 302
    end

    test "#callback performs after_authenticate job after authentication" do
      mock_oauth

      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: true }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_now).with(shop_domain: "shop")

      get :callback, params: @callback_params
      assert_response 302
    end

    private

    def mock_oauth
      host = Base64.strict_encode64("#{ShopifyAPI::Context.host_name}/admin")
      @callback_params = { shop: "shop", code: "code", state: "state", timestamp: "timestamp", host: host,
                           hmac: "hmac", }
      @auth_query = ShopifyAPI::Auth::Oauth::AuthQuery.new(**@callback_params)
      ShopifyAPI::Auth::Oauth::AuthQuery.stubs(:new).with(**@callback_params).returns(@auth_query)

      cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = "nonce"

      ShopifyAPI::Auth::Oauth.expects(:validate_auth_callback).with(cookies:
        {
          ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME =>
            cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME],
        }, auth_query: @auth_query)
        .returns({
          cookie: ShopifyAPI::Auth::Oauth::SessionCookie.new(value: "", expires: Time.now),
          session: ShopifyAPI::Auth::Session.new(shop: "shop", access_token: "token"),
        })
    end
  end
end
