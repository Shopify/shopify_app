# frozen_string_literal: true

require_relative "../../test_helper"

class ShopifyApp::Auth::TokenExchangeTest < ActiveSupport::TestCase
  OFFLINE_ACCESS_TOKEN_TYPE = ShopifyAPI::Auth::TokenExchange::RequestedTokenType::OFFLINE_ACCESS_TOKEN
  ONLINE_ACCESS_TOKEN_TYPE = ShopifyAPI::Auth::TokenExchange::RequestedTokenType::ONLINE_ACCESS_TOKEN

  def setup
    ShopifyApp::SessionRepository.shop_storage = ShopifyApp::InMemoryShopSessionStore
    ShopifyApp::SessionRepository.user_storage = nil

    @shop = "my-shop.myshopify.com"
    @user_id = 1
    @id_token = build_jwt

    @offline_session = build_offline_session
    @online_session = build_online_session

    ShopifyApp.configuration.post_authenticate_tasks.stubs(:perform)
  end

  test "#perform exchanges offline token then stores it when only shop session store is configured" do
    ShopifyAPI::Auth::TokenExchange.expects(:exchange_token).with(
      shop: @shop,
      session_token: @id_token,
      requested_token_type: OFFLINE_ACCESS_TOKEN_TYPE,
    ).once.returns(@offline_session)

    assert_nil ShopifyApp::SessionRepository.load_session(@offline_session.id)

    new_session = ShopifyApp::Auth::TokenExchange.perform(@id_token)

    assert_equal @offline_session, new_session
    assert_equal @offline_session, ShopifyApp::SessionRepository.load_session(@offline_session.id)
  end

  test "#perform exchanges both online and offline tokens then stores it when user session store is configured" do
    ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore

    ShopifyAPI::Auth::TokenExchange.expects(:exchange_token).with(
      shop: @shop,
      session_token: @id_token,
      requested_token_type: OFFLINE_ACCESS_TOKEN_TYPE,
    ).returns(@offline_session)

    ShopifyAPI::Auth::TokenExchange.expects(:exchange_token).with(
      shop: @shop,
      session_token: @id_token,
      requested_token_type: ONLINE_ACCESS_TOKEN_TYPE,
    ).returns(@online_session)

    assert_nil ShopifyApp::SessionRepository.load_session(@offline_session.id)
    assert_nil ShopifyApp::SessionRepository.load_session(@online_session.id)

    new_session = ShopifyApp::Auth::TokenExchange.perform(@id_token)

    assert_equal @online_session, new_session
    assert_equal @offline_session, ShopifyApp::SessionRepository.load_session(@offline_session.id)
    assert_equal @online_session, ShopifyApp::SessionRepository.load_session(@online_session.id)
  end

  test "#perform triggers post_authenticate_tasks after token exchange is complete" do
    ShopifyAPI::Auth::TokenExchange.stubs(:exchange_token).returns(@offline_session)
    ShopifyApp.configuration.post_authenticate_tasks.expects(:perform).with(@offline_session)

    ShopifyApp::Auth::TokenExchange.perform(@id_token)
  end

  test "#perform triggers post_authenticate_tasks after token exchange is complete for online session" do
    ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore

    ShopifyAPI::Auth::TokenExchange.stubs(:exchange_token).returns(@offline_session, @online_session)
    ShopifyApp.configuration.post_authenticate_tasks.expects(:perform).with(@online_session)

    ShopifyApp::Auth::TokenExchange.perform(@id_token)
  end

  test "#perform logs invalid JWT errors from the API and re-raises them" do
    ShopifyAPI::Auth::TokenExchange.stubs(:exchange_token).raises(ShopifyAPI::Errors::InvalidJwtTokenError)

    ShopifyApp::Logger.expects(:error).with(regexp_matches(/Invalid id token/))

    assert_raises ShopifyAPI::Errors::InvalidJwtTokenError do
      ShopifyApp::Auth::TokenExchange.perform(@id_token)
    end
  end

  test "#perform logs HTTP errors coming from Shopify API and re-raises them" do
    response = ShopifyAPI::Clients::HttpResponse.new(code: 401, body: { error: "oops" }.to_json, headers: {})
    error = ShopifyAPI::Errors::HttpResponseError.new(response: response)

    ShopifyAPI::Auth::TokenExchange.stubs(:exchange_token).raises(error)

    ShopifyApp::Logger.expects(:error).with("A 401 error (ShopifyAPI::Errors::HttpResponseError) occurred " \
      "during the token exchange. Response: {\"error\":\"oops\"}")

    assert_raises ShopifyAPI::Errors::HttpResponseError do
      ShopifyApp::Auth::TokenExchange.perform(@id_token)
    end
  end

  test "#perform ignores ActiveRecord::RecordNotUnique when trying to store the token and returns the new token" do
    ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore

    ShopifyAPI::Auth::TokenExchange.expects(:exchange_token).with(
      shop: @shop,
      session_token: @id_token,
      requested_token_type: OFFLINE_ACCESS_TOKEN_TYPE,
    ).returns(@offline_session)

    ShopifyAPI::Auth::TokenExchange.expects(:exchange_token).with(
      shop: @shop,
      session_token: @id_token,
      requested_token_type: ONLINE_ACCESS_TOKEN_TYPE,
    ).returns(@online_session)

    ShopifyApp::SessionRepository.stubs(:store_session).raises(ActiveRecord::RecordNotUnique)

    ShopifyApp::Logger.stubs(:debug)
    ShopifyApp::Logger.expects(:debug).twice.with("Session not stored due to concurrent token exchange calls")

    new_session = ShopifyApp::Auth::TokenExchange.perform(@id_token)

    assert_equal @online_session, new_session
  end

  test "#perform ignores ActiveRecord::RecordInvalid with 'has already been taken' message and returns the new token" do
    ShopifyApp::SessionRepository.user_storage = ShopifyApp::InMemoryUserSessionStore

    ShopifyAPI::Auth::TokenExchange.expects(:exchange_token).with(
      shop: @shop,
      session_token: @id_token,
      requested_token_type: OFFLINE_ACCESS_TOKEN_TYPE,
    ).returns(@offline_session)

    ShopifyAPI::Auth::TokenExchange.expects(:exchange_token).with(
      shop: @shop,
      session_token: @id_token,
      requested_token_type: ONLINE_ACCESS_TOKEN_TYPE,
    ).returns(@online_session)

    record_invalid = ActiveRecord::RecordInvalid.new
    record_invalid.stubs(:message).returns("Validation failed: Shopify domain has already been taken")

    ShopifyApp::SessionRepository.stubs(:store_session).raises(record_invalid)

    ShopifyApp::Logger.stubs(:debug)
    ShopifyApp::Logger.expects(:debug).twice.with("Session not stored due to concurrent token exchange calls")

    new_session = ShopifyApp::Auth::TokenExchange.perform(@id_token)

    assert_equal @online_session, new_session
  end

  test "#perform logs unexpected errors coming from Shopify API and re-raises them" do
    ShopifyAPI::Auth::TokenExchange.stubs(:exchange_token).raises("not today!")

    ShopifyApp::Logger.expects(:error).with("An error occurred during the token exchange: [RuntimeError] not today!")

    assert_raises "not today!" do
      ShopifyApp::Auth::TokenExchange.perform(@id_token)
    end
  end

  private

  def build_jwt(shop: @shop)
    payload = {
      iss: "https://#{shop}/admin",
      dest: "https://#{shop}",
      aud: ShopifyAPI::Context.api_key,
      sub: @user_id.to_s,
      exp: (Time.now + 10).to_i,
      nbf: 1234,
      iat: 1234,
      jti: "4321",
      sid: "abc123",
    }
    JWT.encode(payload, ShopifyAPI::Context.api_secret_key, "HS256")
  end

  def build_offline_session(shop: @shop)
    ShopifyAPI::Auth::Session.new(id: "offline_#{shop}", shop: shop, access_token: "offline-token")
  end

  def build_online_session(shop: @shop, user_id: @user_id)
    user = ShopifyAPI::Auth::AssociatedUser.new(
      id: user_id,
      first_name: "Hello",
      last_name: "World",
      email: "Email",
      email_verified: true,
      account_owner: true,
      locale: "en",
      collaborator: false,
    )

    ShopifyAPI::Auth::Session.new(
      id: "#{shop}_#{user_id}",
      shop: shop,
      is_online: true,
      access_token: "online-token",
      associated_user: user,
    )
  end
end
