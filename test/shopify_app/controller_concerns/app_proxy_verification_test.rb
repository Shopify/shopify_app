# frozen_string_literal: true

require_relative "../../test_helper"

class AppProxyVerificationController < ActionController::Base
  self.allow_forgery_protection = true
  protect_from_forgery with: :exception

  include ShopifyApp::AppProxyVerification

  def basic
    head(:ok)
  end
end

class AppProxyVerificationTest < ActionController::TestCase
  tests AppProxyVerificationController

  # The signed fixtures below were made at this time (2016-06-16 19:41:23 UTC).
  FIXTURE_TIME = Time.at(1466106083)

  setup do
    ShopifyApp.configure do |config|
      config.secret = "secret"
    end
    @original_timestamp_tolerance = ShopifyApp.configuration.app_proxy_timestamp_tolerance
    travel_to FIXTURE_TIME
  end

  teardown do
    ShopifyApp.configuration.app_proxy_timestamp_tolerance = @original_timestamp_tolerance
  end

  test "no_signature" do
    assert_not query_string_valid?("shop=some-random-store.myshopify.com&"\
      "path_prefix=%2Fapps%2Fmy-app&timestamp=1466106083")
  end

  test "basic_query_string" do
    assert query_string_valid?("shop=some-random-store.myshopify.com&path_prefix=%2Fapps%2Fmy-app&timestamp="\
      "1466106083&signature=f5cd7233558b1c50102a6f33c0b63ad1e1072a2fc126cb58d4500f75223cefcd")
    assert_not query_string_valid?("shop=some-random-store.myshopify.com&path_prefix=%2Fapps%2Fmy-app&timestamp="\
      "1466106083&evil=1&signature=f5cd7233558b1c50102a6f33c0b63ad1e1072a2fc126cb58d4500f75223cefcd")
    assert_not query_string_valid?("shop=some-random-store.myshopify.com&path_prefix=%2Fapps%2Fmy-"\
      "app&timestamp=1466106083&evil=1&signature=wrongwrong8b1c50102a6f33c0b63ad1e1072a2fc126cb58d4500f75223cefcd")
  end

  test "query_string_complex_args" do
    assert query_string_valid?("shop=some-random-store.myshopify.com&path_prefix=%2Fapps%2Fmy-app&timestamp"\
      "=1466106083&signature=bbf3aa60e098f08919a2ea4c64a388414f164e6a117a63b03479ac7aa9464b4f&foo=bar&baz[1]"\
      "&baz[2]=b&baz[c[0]]=whatup&baz[c[1]]=notmuch")
    assert query_string_valid?("shop=some-random-store.myshopify.com&path_prefix=%2Fapps%2Fmy-app&"\
      "timestamp=1466106083&foo=bar&baz[1]&baz[2]=b&baz[c[0]]=whatup&baz[c[1]]=notmuch&signature"\
      "=bbf3aa60e098f08919a2ea4c64a388414f164e6a117a63b03479ac7aa9464b4f")
  end

  test "request with invalid signature should fail with 403" do
    with_test_routes do
      invalid_params = {
        shop: "some-random-store.myshopify.com",
        path_prefix: "/apps/my-app",
        timestamp: "1466106083",
        signature: "wrong233558b1c50102a6f33c0b63ad1e1072a2fc126cb58d4500f75223cefcd",
      }
      get :basic, params: invalid_params
      assert_response :forbidden
    end
  end

  test "request with a valid signature should pass" do
    with_test_routes do
      valid_params = {
        shop: "some-random-store.myshopify.com",
        path_prefix: "/apps/my-app",
        timestamp: "1466106083",
        signature: "f5cd7233558b1c50102a6f33c0b63ad1e1072a2fc126cb58d4500f75223cefcd",
      }
      get :basic, params: valid_params
      assert_response :ok
    end
  end

  test "timestamp within the tolerance of now is valid, in either direction" do
    assert query_string_valid?(signed_query(timestamp: FIXTURE_TIME.to_i - 90))
    assert query_string_valid?(signed_query(timestamp: FIXTURE_TIME.to_i + 90))
  end

  test "timestamp outside the tolerance is invalid even with a valid signature" do
    assert_not query_string_valid?(signed_query(timestamp: FIXTURE_TIME.to_i - 91))
    assert_not query_string_valid?(signed_query(timestamp: FIXTURE_TIME.to_i + 91))
  end

  test "missing, blank or non-integer timestamp is invalid" do
    assert_not query_string_valid?(signed_query)
    assert_not query_string_valid?(signed_query(timestamp: ""))
    assert_not query_string_valid?(signed_query(timestamp: "#{FIXTURE_TIME.to_i}.5"))
    assert_not query_string_valid?(signed_query(timestamp: "-#{FIXTURE_TIME.to_i}"))
    assert_not query_string_valid?(signed_query(timestamp: "1e9"))
  end

  test "repeated timestamp is invalid" do
    timestamp = FIXTURE_TIME.to_i
    signature = signature_for(
      "path_prefix" => "/apps/my-app",
      "shop" => "some-random-store.myshopify.com",
      "timestamp" => "#{timestamp},#{timestamp}",
    )

    assert_not query_string_valid?("shop=some-random-store.myshopify.com&path_prefix=%2Fapps%2Fmy-app&"\
      "timestamp=#{timestamp}&timestamp=#{timestamp}&signature=#{signature}")
  end

  test "tolerance is configurable" do
    ShopifyApp.configuration.app_proxy_timestamp_tolerance = 300

    assert query_string_valid?(signed_query(timestamp: FIXTURE_TIME.to_i - 300))
    assert_not query_string_valid?(signed_query(timestamp: FIXTURE_TIME.to_i - 301))
  end

  test "a nil tolerance disables the timestamp check" do
    ShopifyApp.configuration.app_proxy_timestamp_tolerance = nil

    assert query_string_valid?(signed_query(timestamp: FIXTURE_TIME.to_i - 86_400))
    assert query_string_valid?(signed_query)
  end

  test "replaying a signed request after the tolerance fails with 403" do
    with_test_routes do
      query = signed_query(timestamp: FIXTURE_TIME.to_i)

      travel 60.seconds
      get :basic, params: Rack::Utils.parse_query(query)
      assert_response :ok

      travel 5.minutes
      get :basic, params: Rack::Utils.parse_query(query)
      assert_response :forbidden
    end
  end

  private

  def signed_query(timestamp: nil)
    params = { "shop" => "some-random-store.myshopify.com", "path_prefix" => "/apps/my-app" }
    params["timestamp"] = timestamp.to_s unless timestamp.nil?

    "#{params.to_query}&signature=#{signature_for(params)}"
  end

  def signature_for(params)
    sorted_params = params.map { |k, v| "#{k}=#{v}" }.sort.join
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), "secret", sorted_params)
  end

  def query_string_valid?(query_string)
    AppProxyVerificationController.new.send(:query_string_valid?, query_string)
  end

  def with_test_routes
    with_routing do |set|
      set.draw do
        get "/app_proxy/basic" => "app_proxy_verification#basic"
      end
      yield
    end
  end
end
