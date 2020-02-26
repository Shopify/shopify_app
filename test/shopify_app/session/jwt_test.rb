require 'test_helper'

module ShopifyApp
  class JWTTest < ActiveSupport::TestCase
    setup do
      ShopifyApp.configuration.api_key = 'api_key'
      ShopifyApp.configuration.myshopify_domain = 'myshopify.io'
    end

    test "#payload returns the jwt payload" do
      p = payload
      token = ::JWT.encode(p, nil, 'none')
      jwt = JWT.new(token)

      assert_equal p, jwt.payload
    end

    test "#payload returns nil if 'aud' claim doesn't match api_key" do
      ShopifyApp.configuration.api_key = 'other_key'

      p = payload
      token = ::JWT.encode(p, nil, 'none')
      jwt = JWT.new(token)

      assert_nil jwt.payload
    end

    test "#payload returns nil if 'exp' claim is in the past" do
      p = payload(exp: 1.day.ago)
      token = ::JWT.encode(p, nil, 'none')
      jwt = JWT.new(token)

      assert_nil jwt.payload
    end

    test "#payload returns nil if 'nbf' claim is in the future" do
      p = payload(nbf: 1.day.from_now)
      token = ::JWT.encode(p, nil, 'none')
      jwt = JWT.new(token)

      assert_nil jwt.payload
    end

    test "#payload returns nil if `dest` is not a valid shopify domain" do
      p = payload(dest: 'https://example.com')
      token = ::JWT.encode(p, nil, 'none')
      jwt = JWT.new(token)

      assert_nil jwt.payload
    end

    test "#payload returns nil if `iss` host doesn't match `dest` host" do
      p = payload(dest: 'https://other.myshopify.io')
      token = ::JWT.encode(p, nil, 'none')
      jwt = JWT.new(token)

      assert_nil jwt.payload
    end

    private

    def header
      {
        'alg' => 'none',
      }
    end

    def payload(
      api_key: 'api_key',
      iss_host: 'https://test.myshopify.io',
      dest: iss_host,
      exp: 1.day.from_now,
      nbf: 1.day.ago
    )
      {
        'iss' => "#{iss_host}/admin",
        'dest' => dest,
        'aud' => api_key,
        'sub' => 'user_id',
        'exp' => exp.to_i,
        'nbf' => nbf.to_i,
        'iat' => 1.day.ago.to_i,
        'jti' => 'abc',
      }
    end
  end
end
