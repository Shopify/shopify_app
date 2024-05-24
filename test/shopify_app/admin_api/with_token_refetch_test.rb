# frozen_string_literal: true

require "test_helper"

class ShopifyApp::AdminAPI::WithTokenRefetchTest < ActiveSupport::TestCase
  include ShopifyApp::AdminAPI::WithTokenRefetch

  def setup
    @session = ShopifyAPI::Auth::Session.new(id: "session-id", shop: "shop", access_token: "old", expires: 1.hour.ago)
    @id_token = "an-id-token"

    tomorrow = 1.day.from_now
    @new_session = ShopifyAPI::Auth::Session.new(id: "session-id", shop: "shop", access_token: "new", expires: tomorrow)

    @fake_admin_api = stub(:admin_api)
  end

  test "#with_token_refetch takes a block and returns its value" do
    result = with_token_refetch(@session, @id_token) do
      "returned by block"
    end

    assert_equal "returned by block", result
  end

  test "#with_token_refetch rescues Admin API HttpResponseError 401, performs token exchange and retries block" do
    response = ShopifyAPI::Clients::HttpResponse.new(code: 401, body: { error: "oops" }.to_json, headers: {})
    error = ShopifyAPI::Errors::HttpResponseError.new(response: response)
    @fake_admin_api.stubs(:query).raises(error).then.returns("oh now we're good")

    ShopifyApp::Logger.expects(:debug).with("Shopify API returned a 401 Unauthorized error, exchanging token " \
      "and retrying with new session")

    ShopifyApp::Auth::TokenExchange.expects(:perform).with(@id_token).returns(@new_session)

    result = with_token_refetch(@session, @id_token) do
      @fake_admin_api.query
    end

    assert_equal "oh now we're good", result
  end

  test "#with_token_refetch updates original session's attributes when token exchange is performed" do
    response = ShopifyAPI::Clients::HttpResponse.new(code: 401, body: "", headers: {})
    error = ShopifyAPI::Errors::HttpResponseError.new(response: response)
    @fake_admin_api.stubs(:query).raises(error).then.returns("oh now we're good")

    ShopifyApp::Auth::TokenExchange.stubs(:perform).with(@id_token).returns(@new_session)

    with_token_refetch(@session, @id_token) do
      @fake_admin_api.query
    end

    assert_equal @new_session.access_token, @session.access_token
    assert_equal @new_session.expires, @session.expires
  end

  test "#with_token_refetch re-raises when 401 persists" do
    response = ShopifyAPI::Clients::HttpResponse.new(code: 401, body: "401 message", headers: {})
    api_error = ShopifyAPI::Errors::HttpResponseError.new(response: response)

    ShopifyApp::Auth::TokenExchange.stubs(:perform).with(@id_token).returns(@new_session)

    @fake_admin_api.expects(:query).twice.raises(api_error)

    ShopifyApp::Logger.expects(:debug).with("Shopify API returned a 401 Unauthorized error, exchanging token " \
      "and retrying with new session")

    ShopifyApp::Logger.expects(:debug).with("Shopify API returned a 401 Unauthorized error that was not corrected " \
      "with token exchange, re-raising error")

    reraised_error = assert_raises ShopifyAPI::Errors::HttpResponseError do
      with_token_refetch(@session, @id_token) do
        @fake_admin_api.query
      end
    end

    assert_equal reraised_error, api_error
  end

  test "#with_token_refetch re-raises without deleting session when error is not a 401" do
    response = ShopifyAPI::Clients::HttpResponse.new(code: 500, body: { error: "ooops" }.to_json, headers: {})
    api_error = ShopifyAPI::Errors::HttpResponseError.new(response: response)

    @fake_admin_api.expects(:query).raises(api_error)
    ShopifyApp::SessionRepository.expects(:delete_session).never
    ShopifyApp::Logger.expects(:debug).with(regexp_matches(/Encountered error: 500 \- .*ooops.*, re-raising/))

    reraised_error = assert_raises ShopifyAPI::Errors::HttpResponseError do
      with_token_refetch(@session, @id_token) do
        @fake_admin_api.query
      end
    end

    assert_equal reraised_error, api_error
  end
end
