# frozen_string_literal: true

require "test_helper"
require "action_controller"
require "action_controller/base"

class TokenExchangeController < ActionController::Base
  include ShopifyApp::TokenExchange

  around_action :activate_shopify_session

  def index
    render(plain: "OK")
  end
end

class TokenExchangeControllerTest < ActionController::TestCase
  tests TokenExchangeController

  setup do
    @shop = "my-shop.myshopify.com"
    ShopifyApp::JWT.any_instance.stubs(:shopify_domain).returns(@shop)

    @session_token = "this-is-a-session-token"
    @session_token_in_header = "Bearer #{@session_token}"
    request.headers["HTTP_AUTHORIZATION"] = @session_token_in_header

    ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
    ShopifyApp::SessionRepository.user_storage = nil

    @offline_session = ShopifyAPI::Auth::Session.new(id: "offline_session_1", shop: @shop)

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
  end

  test "Exchanges offline token when session doesn't exist" do
    with_application_test_routes do
      ShopifyAPI::Utils::SessionUtils.expects(:current_session_id).twice.with(
        @session_token_in_header,
        nil,
        false,
      ).returns(nil, "offline_#{@shop}")

      ShopifyAPI::Auth::TokenExchange.expects(:exchange_token).with(
        shop: @shop,
        session_token: @session_token,
        requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::OFFLINE_ACCESS_TOKEN,
      ).returns(@offline_session)

      ShopifyAPI::Context.expects(:activate_session).with(@offline_session)

      get :index, params: { shop: @shop }
    end
  end

  test "Exchanges online token if user session store is configured" do
    ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore

    with_application_test_routes do
      ShopifyAPI::Utils::SessionUtils.expects(:current_session_id).twice.with(
        @session_token_in_header,
        nil,
        true,
      ).returns(nil, "online_#{@user.id}")

      ShopifyAPI::Auth::TokenExchange.expects(:exchange_token).with(
        shop: @shop,
        session_token: @session_token,
        requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::OFFLINE_ACCESS_TOKEN,
      ).returns(@offline_session)

      ShopifyAPI::Auth::TokenExchange.expects(:exchange_token).with(
        shop: @shop,
        session_token: @session_token,
        requested_token_type: ShopifyAPI::Auth::TokenExchange::RequestedTokenType::ONLINE_ACCESS_TOKEN,
      ).returns(@online_session)

      ShopifyAPI::Context.expects(:activate_session).with(@online_session)

      get :index, params: { shop: @shop }
    end
  end

  private

  def with_application_test_routes
    with_routing do |set|
      set.draw do
        get "/" => "token_exchange#index"
      end
      yield
    end
  end
end
