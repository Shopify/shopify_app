require 'test_helper'

class SessionsControllerTest < ActionController::TestCase

  setup do
    ShopifyApp::SessionRepository.storage = InMemorySessionStore
    ShopifyApp.configuration = nil
  end

  test "#new should authenticate the shop if the shop param exists" do
    ShopifyApp.configuration.embedded_app = true
    auth_url = '/auth/shopify?shop=my-shop.myshopify.com'
    get :new, shop: 'my-shop'
    assert response.body.match(/window\.top\.location\.href = "#{Regexp.escape(auth_url)}"/)
  end

  test "#new should authenticate the shop if the shop param exists non embedded" do
    ShopifyApp.configuration.embedded_app = false
    auth_url = '/auth/shopify?shop=my-shop.myshopify.com'
    get :new, shop: 'my-shop'
    assert_match "http://test.host/auth/shopify?shop=my-shop.myshopify.com", response.body
  end

  test "#new should trust the shop param over the current session" do
    ShopifyApp.configuration.embedded_app = true
    previously_logged_in_shop_id = 1
    session[:shopify] = previously_logged_in_shop_id
    new_shop_domain = "new-shop.myshopify.com"
    auth_url = "/auth/shopify?shop=#{new_shop_domain}"
    get :new, shop: new_shop_domain
    assert response.body.match(/window\.top\.location\.href = "#{Regexp.escape(auth_url)}"/)
  end

  test "#new should render a full-page if the shop param doesn't exist" do
    get :new
    assert_response :ok
    assert_template :new
  end

  ['my-shop', 'my-shop.myshopify.com', 'https://my-shop.myshopify.com', 'http://my-shop.myshopify.com'].each do |good_url|
    test "#create should authenticate the shop for the URL (#{good_url})" do
      ShopifyApp.configuration.embedded_app = true
      auth_url = '/auth/shopify?shop=my-shop.myshopify.com'
      post :create, shop: good_url
      assert response.body.match(/window\.top\.location\.href = "#{Regexp.escape(auth_url)}"/)
    end
  end

  ['my-shop', 'my-shop.myshopify.io', 'https://my-shop.myshopify.io', 'http://my-shop.myshopify.io'].each do |good_url|
    test "#create should authenticate the shop for the URL (#{good_url}) with custom myshopify_domain" do
      ShopifyApp.configuration.embedded_app = true
      ShopifyApp.configuration.myshopify_domain = 'myshopify.io'
      auth_url = '/auth/shopify?shop=my-shop.myshopify.io'
      post :create, shop: good_url
      assert response.body.match(/window\.top\.location\.href = "#{Regexp.escape(auth_url)}"/)
    end
  end

  ['myshop.com', 'myshopify.com', 'shopify.com', 'two words', 'store.myshopify.com.evil.com', '/foo/bar'].each do |bad_url|
    test "#create should return an error for a non-myshopify URL (#{bad_url})" do
      post :create, shop: bad_url
      assert_redirected_to root_url
    end
  end

  test "#create should render the login page if the shop param doesn't exist" do
    post :create
    assert_redirected_to root_url
  end

  test "#callback should setup a shopify session" do
    mock_shopify_omniauth

    get :callback, shop: 'shop'
    assert_not_nil session[:shopify]
    assert_equal 'shop.myshopify.com', session[:shopify_domain]
  end

  test "#callback should start the WebhooksManager if webhooks are configured" do
    ShopifyApp.configure do |config|
      config.webhooks = [{topic: 'carts/update', address: 'example-app.com/webhooks'}]
    end

    ShopifyApp::WebhooksManager.expects(:queue)

    mock_shopify_omniauth
    get :callback, shop: 'shop'
  end

  test "#callback doesn't run the WebhooksManager if no webhooks are configured" do
    ShopifyApp.configure do |config|
      config.webhooks = []
    end

    ShopifyApp::WebhooksManager.expects(:queue).never

    mock_shopify_omniauth
    get :callback, shop: 'shop'
  end

  test "#destroy should clear shopify from session and redirect to login with notice" do
    shop_id = 1
    session[:shopify] = shop_id
    session[:shopify_domain] = 'shop1.myshopify.com'

    get :destroy

    assert_nil session[:shopify]
    assert_nil session[:shopify_domain]
    assert_redirected_to login_path
    refute flash[:notice].empty?
  end

  private

  def mock_shopify_omniauth
    OmniAuth.config.add_mock(:shopify, provider: :shopify, uid: 'shop.myshopify.com', credentials: {token: '1234'})
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:shopify] if request
    request.env['omniauth.params'] = { shop: 'shop.myshopify.com' } if request
  end

end
