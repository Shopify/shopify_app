# frozen_string_literal: true

require "test_helper"

module Shopify
  class AfterAuthenticateJob < ActiveJob::Base
    def perform; end
  end

  class CustomPostAuthenticateTasks
    class << self
      def perform(session)
      end
    end
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
  SHOP_DOMAIN = "shop.myshopify.io"

  class CallbackControllerTest < ActionController::TestCase
    setup do
      @routes = ShopifyApp::Engine.routes
      ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
      ShopifyApp::SessionRepository.user_storage = nil
      ShopifyAppConfigurer.setup_context
      I18n.locale = :en
      @stubbed_session = ShopifyAPI::Auth::Session.new(shop: SHOP_DOMAIN, access_token: "token")
      @stubbed_cookie = ShopifyAPI::Auth::Oauth::SessionCookie.new(value: "", expires: Time.now)
      @host = "little-shoppe-of-horrors.#{ShopifyApp.configuration.myshopify_domain}"
      host = Base64.strict_encode64(@host + "/admin")
      @callback_params = {
        shop: SHOP_DOMAIN,
        code: "code",
        state: "state",
        timestamp: "timestamp",
        host: host,
        hmac: "hmac",
      }
      @auth_query = ShopifyAPI::Auth::Oauth::AuthQuery.new(**@callback_params)
      request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6)"\
        "AppleWebKit/537.36 (KHTML, like Gecko)"\
        "Chrome/69.0.3497.100 Safari/537.36"
      ShopifyApp::SessionRepository.stubs(:store_session)
    end

    teardown do
      ShopifyApp.configuration.custom_post_authenticate_tasks = nil
      SessionRepository.shop_storage.clear
    end

    test "#callback flashes error in Spanish" do
      I18n.expects(:t).with("could_not_log_in")
      get :callback,
        params: { shop: SHOP_DOMAIN, code: "code", state: "state", timestamp: "timestamp", host: "host", hmac: "hmac" }
    end

    test "#callback rescued errors of ShopifyAPI::Error will not emit a deprecation notice" do
      ShopifyAPI::Auth::Oauth.expects(:validate_auth_callback).raises(ShopifyAPI::Errors::MissingRequiredArgumentError)
      assert_not_deprecated do
        get :callback, params: {
          shop: SHOP_DOMAIN,
          code: "code",
          state: "state",
          timestamp: "timestamp",
          host: "host",
          hmac: "hmac",
        }
      end
      assert_equal flash[:error], "Could not log in to Shopify store"
    end

    test "#callback rescued shopify errors will not be deprecated" do
      response = ShopifyAPI::Clients::HttpResponse.new(code: 500, headers: {}, body: "")
      error = ShopifyAPI::Errors::HttpResponseError.new(response: response)
      ShopifyAPI::Auth::Oauth.expects(:validate_auth_callback).raises(error)

      ShopifyApp::Logger.expects(:deprecated).never
      get :callback,
        params: { shop: SHOP_DOMAIN, code: "code", state: "state", timestamp: "timestamp", host: "host", hmac: "hmac" }
    end

    test "#callback rescued non-shopify errors are re-raised" do
      error = StandardError.new
      ShopifyAPI::Auth::Oauth.expects(:validate_auth_callback).raises(error)

      assert_raise StandardError do
        get :callback,
          params: {
            shop: SHOP_DOMAIN,
            code: "code",
            state: "state",
            timestamp: "timestamp",
            host: "host",
            hmac: "hmac",
          }
      end
    end

    test "#callback calls ShopifyAPI::Auth::Oauth.validate_auth_callback" do
      mock_oauth

      get :callback, params: @callback_params
    end

    test "#callback saves the session when validated by API library" do
      mock_oauth
      ShopifyApp::SessionRepository.expects(:store_session).with(@stubbed_session)

      get :callback, params: @callback_params
    end

    test "#callback returns to root if the host in the param doesn't match configuration indicating a potential phishing attack" do
      host = "hackerman-evil-site.com/hide-yo-wife-hide-yo-kids"
      encoded_host = Base64.strict_encode64(host + "/admin")
      hacker_params = @callback_params.dup
      hacker_params[:host] = encoded_host
      ShopifyAPI::Auth::Oauth::AuthQuery.stubs(:new).with(**hacker_params).returns(@auth_query)
      ShopifyAPI::Auth::Oauth.expects(:validate_auth_callback).returns({
        cookie: @stubbed_cookie,
        session: @stubbed_session,
      })

      get :callback, params: hacker_params
      assert_redirected_to ShopifyApp.configuration.root_url
    end

    test "#callback sets the shopify_user_id in the Rails session when session is online" do
      ShopifyApp::SessionRepository.shop_storage.store(@stubbed_session)
      ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore

      mock_session = online_session
      mock_oauth(session: online_session)

      get :callback, params: @callback_params
      assert_equal session[:shopify_user_id], mock_session.associated_user.id
    end

    test "#callback DOES NOT set the shopify_user_id in the Rails session when session is offline" do
      mock_session = ShopifyAPI::Auth::Session.new(shop: SHOP_DOMAIN, access_token: "token", is_online: false)
      mock_oauth(session: mock_session)
      get :callback, params: @callback_params
      assert_nil session[:shopify_user_id]
    end

    test "#callback sets encrypted cookie if API library returns cookie object" do
      cookie = ShopifyAPI::Auth::Oauth::SessionCookie.new(value: "snickerdoodle", expires: Time.now + 1.day)
      mock_oauth(cookie: cookie)

      get :callback, params: @callback_params
      assert_equal cookies.encrypted[cookie.name], cookie.value
    end

    test "#callback does not set encrypted cookie if API library returns empty cookie" do
      mock_oauth

      get :callback, params: @callback_params
      refute_equal cookies.encrypted[@stubbed_cookie.name], @stubbed_cookie.value
    end

    test "#callback starts the WebhooksManager if webhooks are configured" do
      # Deprecated in 23.0, tests moved to PostAuthenticateTasksTest
      ShopifyApp.configure do |config|
        config.webhooks = [{ topic: "carts/update", address: "example-app.com/webhooks" }]
      end

      ShopifyApp::WebhooksManager.expects(:queue).with(SHOP_DOMAIN, "token")

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback doesn't run the WebhooksManager if no webhooks are configured" do
      # Deprecated in 23.0, tests moved to PostAuthenticateTasksTest
      ShopifyApp.configure do |config|
        config.webhooks = []
      end

      ShopifyApp::WebhooksManager.expects(:queue).never

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback calls #perform_after_authenticate_job and performs inline when inline is true" do
      # Deprecated in 23.0, tests moved to PostAuthenticateTasksTest
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: true }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_now).with(shop_domain: SHOP_DOMAIN)

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback calls #perform_after_authenticate_job and performs asynchronous when inline isn't true" do
      # Deprecated in 23.0, tests moved to PostAuthenticateTasksTest
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: false }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_later).with(shop_domain: SHOP_DOMAIN)

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback doesn't call #perform_after_authenticate_job if job is nil" do
      # Deprecated in 23.0, tests moved to PostAuthenticateTasksTest
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: nil, inline: false }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_later).never

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback calls #perform_after_authenticate_job and performs async if inline isn't present" do
      # Deprecated in 23.0, tests moved to PostAuthenticateTasksTest
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_later).with(shop_domain: SHOP_DOMAIN)

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback calls #perform_after_authenticate_job constantizes from a string to a class" do
      # Deprecated in 23.0, tests moved to PostAuthenticateTasksTest
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: "Shopify::AfterAuthenticateJob", inline: false }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_later).with(shop_domain: SHOP_DOMAIN)

      mock_oauth
      get :callback, params: @callback_params
    end

    test "#callback calls #perform_after_authenticate_job raises if the string is not a valid job class" do
      # Deprecated in 23.0, tests moved to PostAuthenticateTasksTest
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

      non_embedded_host = "not-real.little-test-shoppe-of-horrs.com"
      @controller.stubs(:return_address).returns(non_embedded_host)
      get :callback, params: @callback_params # host is required for App Bridge 2.0

      assert_redirected_to non_embedded_host
    end

    test "callback redirects to the return_to for embedded app when return_to is a fully-formed URL" do
      mock_oauth
      session[:return_to] = "https://example.com/return_to?foo=bar"

      get :callback, params: @callback_params # host is required for App Bridge 2.0

      assert_redirected_to "https://example.com/return_to?foo=bar"
    end

    test "#callback redirects to the embedded app url when app is embedded and return_to is not provided" do
      mock_oauth

      get :callback, params: @callback_params # host is required for App Bridge 2.0

      assert_redirected_to "https://#{@host}/admin/apps/key"
    end

    test "#callback redirects to the embedded app url when app is embedded and return_to is a path" do
      mock_oauth
      session[:return_to] = "/return_to/path"

      get :callback, params: @callback_params # host is required for App Bridge 2.0

      assert_redirected_to "https://#{@host}/admin/apps/key/return_to/path"
    end

    test "#callback performs install_webhook job after authentication" do
      # Deprecated in 23.0, tests moved to PostAuthenticateTasksTest
      mock_oauth

      ShopifyApp.configure do |config|
        config.webhooks = [{ topic: "carts/update", address: "example-app.com/webhooks" }]
      end

      ShopifyApp::WebhooksManager.expects(:queue).with(SHOP_DOMAIN, "token")

      get :callback, params: @callback_params
      assert_response 302
    end

    test "#callback performs install_webhook job with an offline session after an online session OAuth" do
      # Deprecated in 23.0, tests moved to PostAuthenticateTasksTest
      ShopifyApp.configure do |config|
        config.webhooks = [{ topic: "carts/update", address: "example-app.com/webhooks" }]
      end
      ShopifyApp::SessionRepository.shop_storage.store(@stubbed_session)
      ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore

      mock_oauth(session: online_session)

      ShopifyApp::WebhooksManager.expects(:queue).with(SHOP_DOMAIN, "token")

      get :callback, params: @callback_params
      assert_response 302
    ensure
      ShopifyApp::SessionRepository.shop_storage.clear
    end

    test "#callback performs after_authenticate job after authentication" do
      # Deprecated in 23.0, tests moved to PostAuthenticateTasksTest
      mock_oauth

      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: true }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_now).with(shop_domain: SHOP_DOMAIN)

      get :callback, params: @callback_params
      assert_response 302
    end

    test "#callback calls post_authenticate_tasks if custom_post_authenticate_tasks is set" do
      mock_oauth

      ShopifyApp.configure do |_config|
        ShopifyApp.configuration.custom_post_authenticate_tasks = Shopify::CustomPostAuthenticateTasks
      end

      Shopify::CustomPostAuthenticateTasks.expects(:perform).with(@stubbed_session)

      get :callback, params: @callback_params
      assert_response 302
    end

    test "#callback does not call post_authenticate_tasks if custom_post_authenticate_tasks is not set" do
      mock_oauth

      ShopifyApp.configure do |_config|
        ShopifyApp.configuration.custom_post_authenticate_tasks = nil
      end

      Shopify::CustomPostAuthenticateTasks.expects(:perform).never

      get :callback, params: @callback_params
      assert_response 302
    end

    test "#callback calls methods in callback controller if custom_post_authenticate_tasks is not set" do
      mock_oauth

      ShopifyApp.configure do |_config|
        ShopifyApp.configuration.custom_post_authenticate_tasks = nil
      end

      CallbackController.any_instance.expects(:install_webhooks)
      CallbackController.any_instance.expects(:perform_after_authenticate_job)

      get :callback, params: @callback_params
      assert_response 302
    end

    private

    def mock_oauth(cookie: @stubbed_cookie, session: @stubbed_session)
      ShopifyAPI::Auth::Oauth::AuthQuery.stubs(:new).with(**@callback_params).returns(@auth_query)

      cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME] = "nonce"

      ShopifyAPI::Auth::Oauth.expects(:validate_auth_callback).with(
        cookies:
                {
                  ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME =>
                    cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME],
                },
        auth_query: @auth_query,
      )
        .returns({
          cookie: cookie,
          session: session,
        })
    end

    def online_session
      associated_user = ShopifyAPI::Auth::AssociatedUser.new(
        id: 42,
        first_name: "LeeeEEeeeeee3roy",
        last_name: "Jenkins",
        email: "dat_email@tho.com",
        email_verified: true,
        locale: "en",
        collaborator: true,
        account_owner: true,
      )
      ShopifyAPI::Auth::Session.new(
        shop: SHOP_DOMAIN,
        access_token: "online-token",
        is_online: true,
        associated_user: associated_user,
      )
    end
  end
end
