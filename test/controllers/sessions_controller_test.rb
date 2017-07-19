require 'test_helper'

module ShopifyApp
  class SessionsControllerTest < ActionController::TestCase

    setup do
      @routes = ShopifyApp::Engine.routes
      ShopifyApp::SessionRepository.storage = ShopifyApp::InMemorySessionStore
      ShopifyApp.configuration = nil

      I18n.locale = :en
    end

    test "#new should authenticate the shop if a valid shop param exists" do
      shopify_domain = 'my-shop.myshopify.com'
      get :new, params: { shop: 'my-shop' }
      assert_redirected_to_authentication(shopify_domain, response)
    end

    test "#new should authenticate the shop if a valid shop param exists non embedded" do
      ShopifyApp.configuration.embedded_app = false
      auth_url = '/auth/shopify?shop=my-shop.myshopify.com'
      get :new, params: { shop: 'my-shop' }
      assert_redirected_to auth_url
    end

    test "#new should trust the shop param over the current session" do
      previously_logged_in_shop_id = 1
      session[:shopify] = previously_logged_in_shop_id
      new_shop_domain = "new-shop.myshopify.com"
      get :new, params: { shop: new_shop_domain }
      assert_redirected_to_authentication(new_shop_domain, response)
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
        assert_redirected_to_authentication(shopify_domain, response)
      end
    end

    ['my-shop', 'my-shop.myshopify.io', 'https://my-shop.myshopify.io', 'http://my-shop.myshopify.io'].each do |good_url|
      test "#create should authenticate the shop for the URL (#{good_url}) with custom myshopify_domain" do
        ShopifyApp.configuration.myshopify_domain = 'myshopify.io'
        shopify_domain = 'my-shop.myshopify.io'
        post :create, params: { shop: good_url }
        assert_redirected_to_authentication(shopify_domain, response)
      end
    end

    ['myshop.com', 'myshopify.com', 'shopify.com', 'two words', 'store.myshopify.com.evil.com', '/foo/bar'].each do |bad_url|
      test "#create should return an error for a non-myshopify URL (#{bad_url})" do
        post :create, params: { shop: bad_url }
        assert_response :redirect
        assert_redirected_to '/'
      end
    end

    test "#create should render the login page if the shop param doesn't exist" do
      post :create
      assert_redirected_to '/'
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

      get :destroy

      assert_nil session[:shopify]
      assert_nil session[:shopify_domain]
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

    def mock_shopify_omniauth
      OmniAuth.config.add_mock(:shopify, provider: :shopify, uid: 'shop.myshopify.com', credentials: {token: '1234'})
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:shopify] if request
      request.env['omniauth.params'] = { shop: 'shop.myshopify.com' } if request
    end

    def assert_redirected_to_authentication(shop_domain, response)
      auth_url = "/auth/shopify?shop=#{shop_domain}".to_json
      target_origin = "https://#{shop_domain}".to_json

      post_message_handle = "message: 'Shopify.API.remoteRedirect'"
      post_message_link = "normalizedLink.href = #{auth_url}"
      post_message_data = "data: { location: normalizedLink.href }"
      post_message_call = "window.parent.postMessage(data, #{target_origin});"

      assert_includes response.body, post_message_handle
      assert_includes response.body, post_message_link
      assert_includes response.body, post_message_data
      assert_includes response.body, post_message_call
    end

  end
end
