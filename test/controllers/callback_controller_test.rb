# frozen_string_literal: true

require 'test_helper'

module Shopify
  class AfterAuthenticateJob < ActiveJob::Base
    def perform; end
  end
end

module ShopifyApp
  class CallbackControllerTest < ActionController::TestCase
    TEST_SHOPIFY_DOMAIN = "shop.myshopify.com"
    TEST_ASSOCIATED_USER = { "shopify_user_id" => 'test-shopify-user' }
    TEST_SESSION = "this.is.a.user.session"

    setup do
      @routes = ShopifyApp::Engine.routes
      ShopifyApp.configuration = nil
      ShopifyApp.configuration.embedded_app = true

      I18n.locale = :en

      request.env['HTTP_USER_AGENT'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36'
    end

    test '#callback flashes error when omniauth is not present' do
      get :callback, params: { shop: 'shop' }
      assert_equal flash[:error], 'Could not log in to Shopify store'
    end

    test '#callback flashes error in Spanish' do
      I18n.locale = :es
      get :callback, params: { shop: 'shop' }
      assert_match 'sesión', flash[:error]
    end

    test '#callback sets up a shop session for shop token setup' do
      mock_shopify_omniauth

      ShopifyApp::SessionRepository.expects(:store_shop_session).returns('1234')
      get :callback, params: { shop: 'shop' }
      assert_equal '1234', session[:shop_id]
      assert_nil session[:user_id]
      assert_equal TEST_SHOPIFY_DOMAIN, session[:shopify_domain]
    end

    test '#callback sets up a user session for user token setup' do
      mock_shopify_user_omniauth

      ShopifyApp::SessionRepository.expects(:store_user_session).returns('435')
      get :callback, params: { shop: 'shop' }
      assert_nil session[:shop_id]
      assert_equal '435', session[:user_id]
      assert_equal TEST_SHOPIFY_DOMAIN, session[:shopify_domain]
    end

    test '#callback clears a stale shopify_user session if none is provided in latest callback' do
      session[:shopify_user] = 'user_object'
      mock_shopify_omniauth

      get :callback, params: { shop: 'shop' }
      assert_not_nil session[:shop_id]
      assert_nil session[:shopify_user]
    end

    test '#callback sets up a shopify session with a user for online mode' do
      mock_shopify_user_omniauth

      ShopifyApp::SessionRepository.expects(:store_user_session).returns('4321')
      get :callback, params: { shop: 'shop' }
      assert_equal '4321', session[:user_id]
      assert_equal TEST_SHOPIFY_DOMAIN, session[:shopify_domain]
      assert_equal TEST_ASSOCIATED_USER, session[:shopify_user]
      assert_equal TEST_SESSION, session[:user_session]
    end

    test '#callback starts the WebhooksManager if webhooks are configured' do
      ShopifyApp.configure do |config|
        config.webhooks = [{ topic: 'carts/update', address: 'example-app.com/webhooks' }]
      end

      ShopifyApp::WebhooksManager.expects(:queue)

      mock_shopify_omniauth
      get :callback, params: { shop: 'shop' }
    end

    test "#callback doesn't run the WebhooksManager if no webhooks are configured" do
      ShopifyApp.configure do |config|
        config.webhooks = []
      end

      ShopifyApp::WebhooksManager.expects(:queue).never

      mock_shopify_omniauth
      get :callback, params: { shop: 'shop' }
    end

    test '#install_webhooks uses the shop token for shop strategy' do
      shop_session = ShopifyAPI::Session.new(domain: 'shop', token: '1234', api_version: '2019-1')
      ShopifyApp::SessionRepository.expects(:retrieve_shop_session).returns(shop_session)
      ShopifyApp.configure do |config|
        config.webhooks = [{ topic: 'carts/update', address: 'example-app.com/webhooks' }]
      end

      ShopifyApp::WebhooksManager.expects(:queue).with(TEST_SHOPIFY_DOMAIN, '1234', ShopifyApp.configuration.webhooks)

      mock_shopify_omniauth
      get :callback, params: { shop: 'shop' }
    end

    test '#install_webhooks still uses the shop token for user strategy' do
      shop_session = ShopifyAPI::Session.new(domain: 'shop', token: '1234', api_version: '2019-1')
      ShopifyApp::SessionRepository.expects(:retrieve_shop_session).returns(shop_session)
      user_session = ShopifyAPI::Session.new(domain: 'shop', token: '4321', api_version: '2019-1')
      ShopifyApp::SessionRepository.expects(:retrieve_user_session).returns(user_session)
      ShopifyApp.configure do |config|
        config.webhooks = [{ topic: 'carts/update', address: 'example-app.com/webhooks' }]
      end

      ShopifyApp::WebhooksManager.expects(:queue).with(TEST_SHOPIFY_DOMAIN, '1234', ShopifyApp.configuration.webhooks)

      session[:shop_id] = '135'
      mock_shopify_user_omniauth
      get :callback, params: { shop: 'shop' }
    end

    test '#install_webhooks falls back to user token for user strategy if shop is not in session' do
      user_session = ShopifyAPI::Session.new(domain: 'shop', token: '4321', api_version: '2019-1')
      ShopifyApp::SessionRepository.expects(:retrieve_user_session).returns(user_session).times(2)
      ShopifyApp.configure do |config|
        config.webhooks = [{ topic: 'carts/update', address: 'example-app.com/webhooks' }]
      end

      ShopifyApp::WebhooksManager.expects(:queue).with(TEST_SHOPIFY_DOMAIN, '4321', ShopifyApp.configuration.webhooks)

      mock_shopify_user_omniauth
      get :callback, params: { shop: 'shop' }
    end

    test '#callback calls #perform_after_authenticate_job and performs inline when inline is true' do
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: true }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_now)

      mock_shopify_omniauth
      get :callback, params: { shop: 'shop' }
    end

    test "#callback calls #perform_after_authenticate_job and performs asynchronous when inline isn't true" do
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: false }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_later)

      mock_shopify_omniauth
      get :callback, params: { shop: 'shop' }
    end

    test "#callback doesn't call #perform_after_authenticate_job if job is nil" do
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: nil, inline: false }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_later).never

      mock_shopify_omniauth
      get :callback, params: { shop: 'shop' }
    end

    test "#callback calls #perform_after_authenticate_job and performs async if inline isn't present" do
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_later)

      mock_shopify_omniauth
      get :callback, params: { shop: 'shop' }
    end

    test "#callback calls #perform_after_authenticate_job constantizes from a string to a class" do
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: "Shopify::AfterAuthenticateJob", inline: false }
      end

      Shopify::AfterAuthenticateJob.expects(:perform_later)

      mock_shopify_omniauth
      get :callback, params: { shop: 'shop' }
    end

    test "#callback calls #perform_after_authenticate_job raises if the string is not a valid job class" do
      ShopifyApp.configure do |config|
        config.after_authenticate_job = { job: "InvalidJobClassThatDoesNotExist", inline: false }
      end

      mock_shopify_omniauth

      assert_raise NameError do
        get :callback, params: { shop: 'shop' }
      end
    end

    private

    def mock_shopify_omniauth
      ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
      ShopifyApp::SessionRepository.user_storage = nil
      OmniAuth.config.add_mock(:shopify, provider: :shopify, uid: TEST_SHOPIFY_DOMAIN, credentials: { token: '1234' })
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:shopify] if request
      request.env['omniauth.params'] = { shop: TEST_SHOPIFY_DOMAIN } if request
    end

    def mock_shopify_user_omniauth
      ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
      ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore
      OmniAuth.config.add_mock(
        :shopify,
        provider: :shopify,
        uid: TEST_SHOPIFY_DOMAIN,
        credentials: { token: '1234' },
        extra: {
          associated_user: TEST_ASSOCIATED_USER,
          associated_user_scope: "read_products",
          scope: "read_products",
          session: TEST_SESSION
        }
      )
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:shopify] if request
      request.env['omniauth.params'] = { shop: TEST_SHOPIFY_DOMAIN } if request
    end
  end
end
