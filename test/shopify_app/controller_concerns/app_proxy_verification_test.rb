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

  setup do
    ShopifyApp.configure do |config|
      config.secret = "secret"
    end
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

  test "HMAC signature bypass via canonicalization collision is prevented" do
    with_test_routes do
      # VULNERABILITY: The calculated_signature method uses Array(v).join(",")
      # which creates a collision where "1,2" (string) and ["1","2"] (array)
      # produce the same canonical form, allowing signature replay attacks.

      timestamp = "1466106083"
      secret = ShopifyApp.configuration.secret

      # Step 1: Attacker captures/knows a valid signature for STRING parameter "ids=1,2"
      params_for_signing = {
        "ids" => "1,2",
        "path_prefix" => "/apps/my-app",
        "shop" => "some-random-store.myshopify.com",
        "timestamp" => timestamp,
      }

      # This replicates the vulnerable canonicalization: Array("1,2").join(",") => "1,2"
      sorted_params = params_for_signing.collect { |k, v| "#{k}=#{Array(v).join(",")}" }.sort.join
      valid_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, sorted_params)

      # Step 2: Verify the original string-based request works
      string_query = "ids=1,2&path_prefix=/apps/my-app&shop=some-random-store.myshopify.com&" \
        "timestamp=#{timestamp}&signature=#{valid_signature}"
      @request.env["QUERY_STRING"] = string_query
      get :basic
      assert_response :ok, "Legitimate string parameter request should succeed"

      # Step 3: ATTACK - Send ARRAY ["1", "2"] using the STRING's signature
      # Rack parses duplicate params (ids=1&ids=2) as an array ["1", "2"]
      # The vulnerable code: Array(["1","2"]).join(",") => "1,2" (same as string!)
      array_query = "ids=1&ids=2&path_prefix=/apps/my-app&shop=some-random-store.myshopify.com&" \
        "timestamp=#{timestamp}&signature=#{valid_signature}"
      @request.env["QUERY_STRING"] = array_query
      get :basic

      # Step 4: This MUST return 403 Forbidden to prevent the attack
      # If this returns 200 OK, the vulnerability exists!
      assert_response :forbidden, "Array parameter smuggling attack should be rejected"
    end
  end

  private

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
