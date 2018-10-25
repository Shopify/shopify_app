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

    test '#new renders the redirect layout if user agent is Shopify Mobile' do
      request.env['HTTP_USER_AGENT'] = 'Shopify Mobile/iOS'
      get :new, params: { shop: 'my-shop' }
      assert_template 'shared/redirect'
    end

    test '#new renders the redirect layout if user agent is POS' do
      request.env['HTTP_USER_AGENT'] = 'com.jadedpixel.pos'
      get :new, params: { shop: 'my-shop' }
      assert_template 'shared/redirect'
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

    private

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
