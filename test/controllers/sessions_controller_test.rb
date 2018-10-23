require 'test_helper'

module Shopify
  class AfterAuthenticateJob < ActiveJob::Base
    def perform; end
  end
end

module ShopifyApp
  class SessionsControllerTest < ActionController::TestCase

    setup do
      @routes = ShopifyApp::Engine.routes
      ShopifyApp::SessionRepository.storage = ShopifyApp::InMemorySessionStore
      ShopifyApp.configuration = nil
      ShopifyApp.configuration.embedded_app = true

      I18n.locale = :en

      session['shopify.granted_storage_access'] = true
    end

    test '#new redirects to the enable_cookies page if we can\'t set cookies and the user agent supports cookie partitioning' do
      shopify_domain = 'my-shop.myshopify.com'
      request.env['HTTP_USER_AGENT'] = 'Version/12.0 Safari'
      get :new, params: { shop: 'my-shop' }
      assert_redirected_to_top_level(shopify_domain, '/enable_cookies?shop=my-shop.myshopify.com')
    end

    test '#new renders the request_storage_access layout if we do not have storage access' do
      session.delete('shopify.granted_storage_access')
      get :new, params: { shop: 'my-shop' }
      assert_template 'sessions/request_storage_access'
    end

    test '#new redirects to the top-level login if a valid shop param exists' do
      shopify_domain = 'my-shop.myshopify.com'
      get :new, params: { shop: 'my-shop' }
      assert_redirected_to_top_level(shopify_domain)
    end

    test '#new sets the top_level_oauth cookie if a valid shop param exists and user agent supports cookie partitioning' do
      request.env['HTTP_USER_AGENT'] = 'Version/12.0 Safari'
      get :new, params: { shop: 'my-shop' }
      assert_equal true, session['shopify.top_level_oauth']
    end

    test '#new redirects to the auth page if top_level param' do
      get :new, params: { shop: 'my-shop', top_level: true }
      assert_redirected_to '/auth/shopify'
    end

    test "#new should authenticate the shop if a valid shop param exists non embedded" do
      ShopifyApp.configuration.embedded_app = false
      get :new, params: { shop: 'my-shop' }
      assert_redirected_to '/auth/shopify'
      assert_equal session['shopify.omniauth_params'][:shop], 'my-shop.myshopify.com'
    end

    test '#new authenticates the shop if we\'ve just returned from top-level login flow' do
      session['shopify.top_level_oauth'] = true
      get :new, params: { shop: 'my-shop', top_level: true }
      assert_redirected_to '/auth/shopify'
      assert_equal session['shopify.omniauth_params'][:shop], 'my-shop.myshopify.com'
    end

    test '#new removes the top_level_oauth cookie if the user agent supports partitioning and we\'ve just returned from top-level login flow where the cookies_persist cookie was set' do
      session.delete('shopify.granted_storage_access')
      session['shopify.top_level_oauth'] = true
      session['shopify.cookies_persist'] = true
      request.env['HTTP_USER_AGENT'] = 'Version/12.0 Safari'
      get :new, params: { shop: 'my-shop' }
      assert_nil session['shopify.top_level_oauth']
    end

    test "#new should trust the shop param over the current session" do
      previously_logged_in_shop_id = 1
      session[:shopify] = previously_logged_in_shop_id
      session['shopify.granted_storage_access'] = true
      new_shop_domain = "new-shop.myshopify.com"
      get :new, params: { shop: new_shop_domain }
      assert_redirected_to_top_level(new_shop_domain)
    end

    test "#new should render a full-page if the shop param doesn't exist" do
      get :new
      assert_response :ok
      assert_match %r{Shopify App — Installation}, response.body
    end

    test "#new should render a full-page if the shop param value is not a shop" do
      non_shop_address = "example.com"
      get :new, params: { shop: non_shop_address }
      assert_response :ok
      assert_match %r{Shopify App — Installation}, response.body
    end

    ['my-shop', 'my-shop.myshopify.com', 'https://my-shop.myshopify.com', 'http://my-shop.myshopify.com'].each do |good_url|
      test "#create should authenticate the shop for the URL (#{good_url})" do
        shopify_domain = 'my-shop.myshopify.com'
        post :create, params: { shop: good_url }
        assert_redirected_to_top_level(shopify_domain)
      end
    end

    ['my-shop', 'my-shop.myshopify.io', 'https://my-shop.myshopify.io', 'http://my-shop.myshopify.io'].each do |good_url|
      test "#create should authenticate the shop for the URL (#{good_url}) with custom myshopify_domain" do
        ShopifyApp.configuration.myshopify_domain = 'myshopify.io'
        shopify_domain = 'my-shop.myshopify.io'
        post :create, params: { shop: good_url }
        assert_redirected_to_top_level(shopify_domain)
      end
    end

    ['myshop.com', 'myshopify.com', 'shopify.com', 'two words', 'store.myshopify.com.evil.com', '/foo/bar'].each do |bad_url|
      test "#create should return an error for a non-myshopify URL (#{bad_url})" do
        post :create, params: { shop: bad_url }
        assert_response :redirect
        assert_redirected_to '/'
        assert_equal I18n.t('invalid_shop_url'), flash[:error]
      end
    end

    test "#create should render the login page if the shop param doesn't exist" do
      post :create
      assert_redirected_to '/'
    end

    test '#enable_cookies renders the correct template' do
      get :enable_cookies, params: { shop: 'shop' }
      assert_template 'sessions/enable_cookies'
    end

    test '#enable_cookies displays an error if no shop is provided' do
      get :enable_cookies
      assert_redirected_to ShopifyApp.configuration.root_url
      assert_equal I18n.t('invalid_shop_url'), flash[:error]
    end

    test '#top_level_interaction renders the ccorrect template' do
      get :top_level_interaction, params: { shop: 'shop' }
      assert_template 'sessions/top_level_interaction'
    end

    test '#top_level_interaction displays an error if no shop is provided' do
      get :top_level_interaction
      assert_redirected_to ShopifyApp.configuration.root_url
      assert_equal I18n.t('invalid_shop_url'), flash[:error]
    end

    test '#granted_storage_access displays an error if no shop is provided' do
      get :granted_storage_access
      assert_redirected_to ShopifyApp.configuration.root_url
      assert_equal I18n.t('invalid_shop_url'), flash[:error]
    end

    test '#granted_storage_access sets shopify.granted_storage_access' do
      get :granted_storage_access, params: { shop: 'shop' }

      assert_equal true, session['shopify.granted_storage_access']
    end

    test '#granted_storage_access redirects to app root url with shop param' do
      get :granted_storage_access, params: { shop: 'shop.myshopify.com' }

      assert_redirected_to "#{ShopifyApp.configuration.root_url}?shop=shop.myshopify.com"
    end

    test '#callback should flash error when omniauth is not present' do
      get :callback, params: { shop: 'shop' }
      assert_equal flash[:error], 'Could not log in to Shopify store'
    end

    test '#callback should flash error in Spanish' do
      I18n.locale = :es
      get :callback, params: { shop: 'shop' }
      assert_equal flash[:error], 'No se pudo iniciar sesión en tu tienda de Shopify'
    end

    test "#callback should setup a shopify session" do
      mock_shopify_omniauth

      get :callback, params: { shop: 'shop' }
      assert_not_nil session[:shopify]
      assert_equal 'shop.myshopify.com', session[:shopify_domain]
    end

    test "#callback should setup a shopify session with a user for online mode" do
      mock_shopify_user_omniauth

      get :callback, params: { shop: 'shop' }
      assert_not_nil session[:shopify]
      assert_equal 'shop.myshopify.com', session[:shopify_domain]
      assert_equal 'user_object', session[:shopify_user]
    end

    test "#callback should start the WebhooksManager if webhooks are configured" do
      ShopifyApp.configure do |config|
        config.webhooks = [{topic: 'carts/update', address: 'example-app.com/webhooks'}]
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

    test "#destroy should clear shopify from session and redirect to login with notice" do
      shop_id = 1
      session[:shopify] = shop_id
      session[:shopify_domain] = 'shop1.myshopify.com'
      session[:shopify_user] = { 'id' => 1, 'email' => 'foo@example.com' }

      get :destroy

      assert_nil session[:shopify]
      assert_nil session[:shopify_domain]
      assert_nil session[:shopify_user]
      assert_redirected_to login_path
      assert_equal 'Successfully logged out', flash[:notice]
    end

    test '#destroy should redirect with notice in spanish' do
      I18n.locale = :es
      shop_id = 1
      session[:shopify] = shop_id
      session[:shopify_domain] = 'shop1.myshopify.com'

      get :destroy

      assert_equal 'Cerrar sesión', flash[:notice]
    end

    test "#callback calls #perform_after_authenticate_job and performs inline when inline is true" do
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

    private

    def mock_shopify_omniauth
      OmniAuth.config.add_mock(:shopify, provider: :shopify, uid: 'shop.myshopify.com', credentials: {token: '1234'})
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:shopify] if request
      request.env['omniauth.params'] = { shop: 'shop.myshopify.com' } if request
    end

    def mock_shopify_user_omniauth
      OmniAuth.config.add_mock(:shopify,
        provider: :shopify,
        uid: 'shop.myshopify.com',
        credentials: {token: '1234'},
        extra: {associated_user: 'user_object'}
      )
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:shopify] if request
      request.env['omniauth.params'] = { shop: 'shop.myshopify.com' } if request
    end

    def assert_redirected_to_top_level(shop_domain, expected_url = nil)
      expected_url ||= "/login?shop=#{shop_domain}\\u0026top_level=true"

      assert_template 'shared/redirect'
      assert_select '[id=redirection-target]', 1 do |elements|
        assert_equal "{\"myshopifyUrl\":\"https://#{shop_domain}\",\"url\":\"#{expected_url}\"}",
          elements.first['data-target']
      end
    end
  end
end
