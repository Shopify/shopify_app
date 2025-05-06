# frozen_string_literal: true

require "test_helper"
require "action_controller"
require "action_controller/base"
require "json"

class ApiClass
  def self.perform; end
end

class TokenExchangeController < ActionController::Base
  include ShopifyApp::TokenExchange

  around_action :activate_shopify_session

  def index
    render(plain: "OK")
  end

  def reloaded_path
    render(plain: "OK")
  end

  def make_api_call
    ApiClass.perform
    render(plain: "OK")
  end

  def ensure_render
  ensure
    render(plain: "OK")
  end
end

class MockPostAuthenticateTasks
  def self.perform(session)
  end
end

class TokenExchangeControllerTest < ActionController::TestCase
  tests TokenExchangeController

  setup do
    @shop = "my-shop.myshopify.com"
    @id_token = "this-is-an-id-token"
    @id_token_in_header = "Bearer #{@id_token}"
    request.headers["HTTP_AUTHORIZATION"] = @id_token_in_header

    ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
    ShopifyApp::SessionRepository.user_storage = nil

    @user = ShopifyAPI::Auth::AssociatedUser.new(
      id: 1,
      first_name: "Hello",
      last_name: "World",
      email: "Email",
      email_verified: true,
      account_owner: true,
      locale: "en",
      collaborator: false,
    )
    @online_session = ShopifyAPI::Auth::Session.new(
      id: "online_session_1",
      shop: @shop,
      is_online: true,
      associated_user: @user,
    )
    @offline_session = ShopifyAPI::Auth::Session.new(id: "offline_session_1", shop: @shop)

    @offline_session_id = "offline_#{@shop}"
    @online_session_id = "online_#{@user.id}"

    ShopifyApp.configuration.check_session_expiry_date = true
    ShopifyApp.configuration.custom_post_authenticate_tasks = MockPostAuthenticateTasks
  end

  test "Exchanges token when session doesn't exist" do
    with_application_test_routes do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).with(
        id_token: @id_token,
        online: false,
      ).returns(nil, @offline_session_id)

      ShopifyApp::Auth::TokenExchange.expects(:perform).with(@id_token) do
        ShopifyApp::SessionRepository.store_session(@offline_session)
      end

      ShopifyAPI::Context.expects(:activate_session).with(@offline_session)

      get :index, params: { shop: @shop }
    end
  end

  test "Exchanges token with id_token from URL param when auth header doesn't exist" do
    request.headers["HTTP_AUTHORIZATION"] = nil
    with_application_test_routes do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).with(
        id_token: @id_token,
        online: false,
      ).returns(nil, @offline_session_id)

      ShopifyApp::Auth::TokenExchange.expects(:perform).with(@id_token) do
        ShopifyApp::SessionRepository.store_session(@offline_session)
      end

      ShopifyAPI::Context.expects(:activate_session).with(@offline_session)

      get :index, params: { shop: @shop, id_token: @id_token }
    end
  end

  test "Use existing shop session if it exists" do
    ShopifyApp::SessionRepository.store_shop_session(@offline_session)

    with_application_test_routes do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).with(
        id_token: @id_token,
        online: false,
      ).returns(@offline_session_id)

      ShopifyApp::Auth::TokenExchange.expects(:perform).never

      ShopifyAPI::Context.expects(:activate_session).with(@offline_session)

      get :index, params: { shop: @shop }
    end
  end

  test "Use existing user session if it exists" do
    ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore
    ShopifyApp::SessionRepository.store_user_session(@online_session, @user)

    with_application_test_routes do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).with(
        id_token: @id_token,
        online: true,
      ).returns(@online_session_id)

      ShopifyApp::Auth::TokenExchange.expects(:perform).never

      ShopifyAPI::Context.expects(:activate_session).with(@online_session)

      get :index, params: { shop: @shop }
    end
  end

  test "Exchange token again if current user session is expired" do
    ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore
    ShopifyApp::SessionRepository.store_user_session(@online_session, @user)
    @online_session.stubs(:expired?).returns(true)

    with_application_test_routes do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).with(
        id_token: @id_token,
        online: true,
      ).returns(@online_session_id)

      ShopifyApp::Auth::TokenExchange.expects(:perform).with(@id_token) do
        ShopifyApp::SessionRepository.store_session(@offline_session)
        ShopifyApp::SessionRepository.store_session(@online_session)
      end

      ShopifyAPI::Context.expects(:activate_session).with(@online_session)

      get :index, params: { shop: @shop }
    end
  end

  test "Exchange token again if id_token is present" do
    ShopifyApp::SessionRepository.store_shop_session(@offline_session)

    with_application_test_routes do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).with(
        id_token: @id_token,
        online: false,
      ).returns(@offline_session_id)

      ShopifyApp::Auth::TokenExchange.expects(:perform).with(@id_token) do
        ShopifyApp::SessionRepository.store_session(@offline_session)
      end

      ShopifyAPI::Context.expects(:activate_session).with(@offline_session)

      get :index, params: { shop: @shop, id_token: @id_token }
    end
  end

  test "Don't exchange token if check_session_expiry_date config is false" do
    ShopifyApp.configuration.check_session_expiry_date = false
    ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore
    ShopifyApp::SessionRepository.store_user_session(@online_session, @user)
    @online_session.stubs(:expired?).returns(true)

    with_application_test_routes do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).with(
        id_token: @id_token,
        online: true,
      ).returns(@online_session_id)

      ShopifyApp::Auth::TokenExchange.expects(:perform).never

      ShopifyAPI::Context.expects(:activate_session).with(@online_session)

      get :index, params: { shop: @shop }
    end
  end

  test "Wraps action in with_token_refetch" do
    ShopifyApp::SessionRepository.store_shop_session(@offline_session)
    ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).returns(@offline_session_id)

    ApiClass.expects(:perform)
    @controller.expects(:with_token_refetch).yields

    with_application_test_routes do
      get :make_api_call, params: { shop: @shop }
    end
  end

  [
    ShopifyAPI::Errors::InvalidJwtTokenError,
    ShopifyAPI::Errors::MissingJwtTokenError,
  ].each do |invalid_shopify_id_token_error|
    test "Redirects to bounce page if Shopify ID token is invalid with #{invalid_shopify_id_token_error}" do
      ShopifyApp.configuration.root_url = "/my-root"
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).raises(invalid_shopify_id_token_error)
      request.headers["HTTP_AUTHORIZATION"] = nil

      params = { shop: @shop, my_param: "for-keeps", id_token: "dont-include-this-id-token", embedded: "1" }
      reload_url = CGI.escape("/reloaded_path?embedded=1&my_param=for-keeps&shop=#{@shop}")
      expected_redirect_url = "https://test.host/my-root/patch_shopify_id_token"\
        "?embedded=1&my_param=for-keeps&shop=#{@shop}"\
        "&shopify-reload=#{reload_url}"

      with_application_test_routes do
        get :reloaded_path, params: params
        assert_redirected_to expected_redirect_url
      end
    end

    test "Redirects to embed app if Shopify ID token is invalid with #{invalid_shopify_id_token_error} and embedded param is missing" do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).raises(invalid_shopify_id_token_error)
      request.headers["HTTP_AUTHORIZATION"] = nil

      host = Base64.encode64("#{@shop}/admin")
      params = { shop: @shop, host: host }

      expected_redirect_url = "https://my-shop.myshopify.com/admin/apps/key/"

      with_application_test_routes do
        get :index, params: params
        assert_redirected_to expected_redirect_url
      end
    end

    test "Redirects to embed app if Shopify ID token is invalid with #{invalid_shopify_id_token_error} and embedded and host params are missing" do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).raises(invalid_shopify_id_token_error)
      request.headers["HTTP_AUTHORIZATION"] = nil

      params = { shop: @shop }

      expected_redirect_url = "https://my-shop.myshopify.com/admin/apps/key/"

      with_application_test_routes do
        get :index, params: params
        assert_redirected_to expected_redirect_url
      end
    end

    test "Redirects to login when trying to embed app with missing shop and host params - #{invalid_shopify_id_token_error}" do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).raises(invalid_shopify_id_token_error)
      request.headers["HTTP_AUTHORIZATION"] = nil

      with_application_test_routes do
        get :index
        assert_redirected_to ShopifyApp.configuration.login_url
      end
    end

    test "Responds with unauthorized if Shopify Id token is invalid with #{invalid_shopify_id_token_error} and authorization header exists" do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).raises(invalid_shopify_id_token_error)
      request.headers["HTTP_AUTHORIZATION"] = @id_token_in_header
      expected_response = { errors: [{ message: :unauthorized }] }

      with_application_test_routes do
        get :make_api_call, params: { shop: @shop }

        assert_response :unauthorized
        assert_equal expected_response.to_json, response.body
        assert_equal 1, response.headers["X-Shopify-Retry-Invalid-Session-Request"]
      end
    end

    test "Redirects to bounce page from Token Exchange if Shopify ID token is invalid with #{invalid_shopify_id_token_error}" do
      ShopifyApp.configuration.root_url = "/my-root"
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).returns(nil, @offline_session_id)
      ShopifyApp::Auth::TokenExchange.expects(:perform).raises(invalid_shopify_id_token_error)
      request.headers["HTTP_AUTHORIZATION"] = nil

      params = { shop: @shop, my_param: "for-keeps", id_token: "dont-include-this-id-token", embedded: "1" }
      reload_url = CGI.escape("/reloaded_path?embedded=1&my_param=for-keeps&shop=#{@shop}")
      expected_redirect_url = "https://test.host/my-root/patch_shopify_id_token"\
        "?embedded=1&my_param=for-keeps&shop=#{@shop}"\
        "&shopify-reload=#{reload_url}"

      with_application_test_routes do
        get :reloaded_path, params: params
        assert_redirected_to expected_redirect_url
      end
    end

    test "Responds with unauthorized from Token Exchange if Shopify Id token is invalid with #{invalid_shopify_id_token_error} and authorization header exists" do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).returns(nil, @offline_session_id)
      ShopifyApp::Auth::TokenExchange.expects(:perform).raises(invalid_shopify_id_token_error)

      expected_response = { errors: [{ message: :unauthorized }] }

      with_application_test_routes do
        get :make_api_call, params: { shop: @shop }

        assert_response :unauthorized
        assert_equal expected_response.to_json, response.body
        assert_equal 1, response.headers["X-Shopify-Retry-Invalid-Session-Request"]
      end
    end

    test "Redirects to bounce page from with_token_refetch if Shopify ID token is invalid with #{invalid_shopify_id_token_error}" do
      ShopifyApp.configuration.root_url = "/my-root"
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).returns(@offline_session_id)
      ShopifyApp::Auth::TokenExchange.stubs(:perform)
      request.headers["HTTP_AUTHORIZATION"] = nil

      @controller.expects(:with_token_refetch).raises(invalid_shopify_id_token_error)

      params = { shop: @shop, my_param: "for-keeps", id_token: "dont-include-this-id-token", embedded: "1" }
      reload_url = CGI.escape("/reloaded_path?embedded=1&my_param=for-keeps&shop=#{@shop}")
      expected_redirect_url = "https://test.host/my-root/patch_shopify_id_token"\
        "?embedded=1&my_param=for-keeps&shop=#{@shop}"\
        "&shopify-reload=#{reload_url}"

      with_application_test_routes do
        get :reloaded_path, params: params
        assert_redirected_to expected_redirect_url
      end
    end

    test "Responds with unauthorized from with_token_refetch if Shopify Id token is invalid with #{invalid_shopify_id_token_error} and authorization header exists" do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).returns(@offline_session_id)
      ShopifyApp::Auth::TokenExchange.stubs(:perform)
      expected_response = { errors: [{ message: :unauthorized }] }

      @controller.expects(:with_token_refetch).raises(invalid_shopify_id_token_error)

      with_application_test_routes do
        get :make_api_call, params: { shop: @shop }

        assert_response :unauthorized
        assert_equal expected_response.to_json, response.body
        assert_equal 1, response.headers["X-Shopify-Retry-Invalid-Session-Request"]
      end
    end

    test "Does not redirect to bounce page if redirect/response has been performed already - #{invalid_shopify_id_token_error}" do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).returns(@offline_session_id)
      ShopifyApp::Auth::TokenExchange.stubs(:perform)
      request.headers["HTTP_AUTHORIZATION"] = nil

      @controller.expects(:with_token_refetch).raises(invalid_shopify_id_token_error)
      @controller.stubs(:performed?).returns(false, true)

      with_application_test_routes do
        get :ensure_render, params: { shop: @shop }
        assert_response :ok
      end
    end

    test "Does not respond 401 if redirect/response has been performed already - #{invalid_shopify_id_token_error}" do
      ShopifyAPI::Utils::SessionUtils.stubs(:session_id_from_shopify_id_token).returns(@offline_session_id)
      ShopifyApp::Auth::TokenExchange.stubs(:perform)

      @controller.expects(:with_token_refetch).raises(invalid_shopify_id_token_error)
      @controller.stubs(:performed?).returns(false, true)

      with_application_test_routes do
        get :ensure_render, params: { shop: @shop }
        assert_response :ok
      end
    end
  end

  private

  def with_application_test_routes
    with_routing do |set|
      set.draw do
        get "/" => "token_exchange#index"
        get "/make_api_call" => "token_exchange#make_api_call"
        get "/reloaded_path" => "token_exchange#reloaded_path"
        get "/ensure_render" => "token_exchange#ensure_render"
      end
      yield
    end
  end
end
