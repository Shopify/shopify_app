# frozen_string_literal: true

require 'test_helper'

class SessionTokenProtectionController < ActionController::Base
  include ShopifyApp::SessionTokenProtection
  around_action :activate_shopify_session, only: [:index]

  def index
    render(plain: 'OK')
  end

  def index_unauthorized
    response.set_header('Mock-Header', 'Mock-Value')
    signal_access_token_required
    render(plain: 'Unauthorized')
  end

  def index_with_shopify_domain
    render(plain: current_shopify_domain)
  end
end

class SessionTokenProtectionControllerTest < ActionController::TestCase
  tests SessionTokenProtectionController

  setup do
    ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
    ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore

    ShopifyApp.configuration.allow_jwt_authentication = true
  end

  test '#activate_shopify_session returns 401 Unauthorized with \
  X_Shopify_API_Request_Failure_Unauthorized header if user_session is \
  expected and user_session is blank' do
    with_application_test_routes do
      get :index, params: { shop: 'foobar' }, xhr: true

      assert_equal 401, response.status
    end
  end

  test '#activate_shopify_session returns 401 Unauthorized when user_session \
  blank and user_session expected with valid shop_session' do
    expected_session = ShopifyAPI::Session.new(
      domain: mock_domain,
      token: mock_token,
      api_version: '2020-01',
    )

    ShopifyApp::SessionRepository.expects(:retrieve_user_session_by_shopify_user_id).never
    ShopifyApp::SessionRepository.expects(:retrieve_shop_session_by_shopify_domain)
      .with(mock_dest).returns(expected_session)

    with_application_test_routes do
      request.env['jwt.shopify_domain'] = mock_dest
      get :index, xhr: true

      assert_equal 401, response.status
      assert_equal expected_session, @controller.current_shopify_session
    end
  end

  test '#activate_shopify_session returns 401 Unauthorized if current_shopify_session is blank' do
    # user_session storage is not expected
    ShopifyApp::SessionRepository.user_storage = nil

    with_application_test_routes do
      get :index, params: { shop: mock_dest }, xhr: true

      assert_equal 401, response.status
    end
  end

  test '#current_shopify_session returns nil when no session saved' do
    with_application_test_routes do
      get :index

      assert_nil @controller.current_shopify_session
    end
  end

  test '#current_shopify_session retrieves user_session using jwt' do
    expected_session = ShopifyAPI::Session.new(
      domain: mock_domain,
      token: mock_token,
      api_version: '2020-01',
    )

    ShopifyApp::SessionRepository.expects(:retrieve_user_session_by_shopify_user_id)
      .at_most(2).with(mock_sub).returns(expected_session)
    ShopifyApp::SessionRepository.expects(:retrieve_user_session).never
    ShopifyApp::SessionRepository.expects(:retrieve_shop_session_by_shopify_domain).never
    ShopifyApp::SessionRepository.expects(:retrieve_shop_session).never

    with_application_test_routes do
      request.env['jwt.shopify_domain'] = mock_dest
      request.env['jwt.shopify_user_id'] = mock_sub
      get :index

      assert_equal expected_session, @controller.current_shopify_session
    end
  end

  test '#current_shopify_session retrieves shop session using jwt' do
    expected_session = ShopifyAPI::Session.new(
      domain: mock_domain,
      token: mock_token,
      api_version: '2020-01',
    )

    ShopifyApp::SessionRepository.expects(:retrieve_user_session_by_shopify_user_id).never
    ShopifyApp::SessionRepository.expects(:retrieve_user_session).never
    ShopifyApp::SessionRepository.expects(:retrieve_shop_session_by_shopify_domain)
      .with(mock_dest).returns(expected_session)
    ShopifyApp::SessionRepository.expects(:retrieve_shop_session).never

    with_application_test_routes do
      request.env['jwt.shopify_domain'] = mock_dest
      get :index

      assert_equal expected_session, @controller.current_shopify_session
    end
  end

  test '#current_shopify_session is memoized and does not retrieve session twice' do
    # user_session storage is not expected
    ShopifyApp::SessionRepository.user_storage = nil

    expected_session = ShopifyAPI::Session.new(
      domain: mock_domain,
      token: mock_token,
      api_version: '2020-01',
    )

    ShopifyApp::SessionRepository.expects(:retrieve_shop_session_by_shopify_domain)
      .with(mock_dest).returns(expected_session).once

    with_application_test_routes do
      request.env['jwt.shopify_domain'] = mock_dest
      get :index, xhr: true

      assert @controller.current_shopify_session
    end
  end

  test '#current_shopify_domain raises ShopifyDomainNotFound error if domain not found' do
    assert_raise ShopifyApp::SessionTokenProtection::ShopifyDomainNotFound do
      with_application_test_routes do
        get :current_shopify_domain
      end
    end
  end

  test '#current_shopify_domain returns shopify_domain when provided by jwt' do
    with_application_test_routes do
      request.env['jwt.shopify_domain'] = mock_dest
      get :index_with_shopify_domain, xhr: true

      assert_equal mock_dest, response.body
    end
  end

  test 'signal_access_token_required sets X-Shopify-API-Request-Unauthorized header' do
    with_application_test_routes do
      get :index_unauthorized
      assert_equal true, response.get_header('X-Shopify-API-Request-Failure-Unauthorized')
    end
  end

  test 'signal_access_token_required does not overwrite previously set headers' do
    with_application_test_routes do
      get :index_unauthorized
      assert_equal 'Mock-Value', response.get_header('Mock-Header')
      assert_equal true, response.get_header('X-Shopify-API-Request-Failure-Unauthorized')
    end
  end

  private

  def mock_domain
    'https://test.myshopify.io'
  end

  def mock_token
    'admin_api_token'
  end

  def mock_dest
    'test.shopify.com'
  end

  def mock_sub
    'shopify_user'
  end

  def with_application_test_routes
    with_routing do |set|
      set.draw do
        get '/' => 'session_token_protection#index'
        get '/current_shopify_domain' => 'session_token_protection#current_shopify_domain'
        get '/index_unauthorized' => 'session_token_protection#index_unauthorized'
        get '/index_with_shopify_domain' => 'session_token_protection#index_with_shopify_domain'
      end
      yield
    end
  end
end
