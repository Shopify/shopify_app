# frozen_string_literal: true

require 'test_helper'

module Shopify
  class AfterAuthenticateJob < ActiveJob::Base
    def perform; end
  end
end

module ShopifyApp
  class CallbackControllerTest < ActionController::TestCase
    setup do
      @routes = ShopifyApp::Engine.routes
      ShopifyApp::SessionRepository.storage = ShopifyApp::InMemorySessionStore
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
      assert_equal flash[:error], 'No se pudo iniciar sesión en tu tienda de Shopify'
    end

    test '#callback sets up a shopify session' do
      mock_shopify_omniauth

      get :callback, params: { shop: 'shop' }
      assert_not_nil session[:shopify]
      assert_equal 'shop.myshopify.com', session[:shopify_domain]
    end

    test '#callback clears a stale shopify_user session if none is provided in latest callback' do
      session[:shopify_user] = 'user_object'
      mock_shopify_omniauth

      get :callback, params: { shop: 'shop' }
      assert_not_nil session[:shopify]
      assert_nil session[:shopify_user]
    end

    test '#callback sets up a shopify session with a user for online mode' do
      mock_shopify_user_omniauth

      get :callback, params: { shop: 'shop' }
      assert_not_nil session[:shopify]
      assert_equal 'shop.myshopify.com', session[:shopify_domain]
      assert_equal(OmniAuth::AuthHash.new({token: '1234'}), session[:shopify_user])
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
      OmniAuth.config.add_mock(:shopify, provider: :shopify, uid: 'shop.myshopify.com', credentials: { token: '1234' })
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:shopify] if request
      request.env['omniauth.params'] = { shop: 'shop.myshopify.com' } if request
    end

    def mock_shopify_user_omniauth
      OmniAuth.config.add_mock(
        :shopify,
        provider: :shopify,
        uid: 'shop.myshopify.com',
        credentials: { token: '1234' },
        extra: { associated_user: { } }
      )
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:shopify] if request
      request.env['omniauth.params'] = { shop: 'shop.myshopify.com' } if request
    end
  end
end
