# frozen_string_literal: true
module ShopifyApp
  class JWT
    def initialize(token)
      @token = token
      set_payload
    end

    def shopify_domain
      payload && dest_host
    end

    def shopify_user_id
      payload && payload['sub']
    end

    private

    def payload
      return unless @payload
      return unless dest_host
      return unless dest_host == iss_host
      return unless @payload['aud'] == ShopifyApp.configuration.api_key

      @payload
    end

    def set_payload
      @payload, _ = parse_token_data(ShopifyApp.configuration.secret)
      configuration_old_secret = @payload && ShopifyApp.configuration
      @payload, _ = parse_token_data(ShopifyApp.configuration.old_secret) unless configuration_old_secret
    end

    def parse_token_data(secret)
      ::JWT.decode(@token, secret, true, { algorithm: 'HS256' })
    rescue ::JWT::DecodeError, ::JWT::VerificationError, ::JWT::ExpiredSignature, ::JWT::ImmatureSignature
      nil
    end

    def dest_host
      @payload && ShopifyApp::Utils.sanitize_shop_domain(@payload['dest'])
    end

    def iss_host
      @payload && ShopifyApp::Utils.sanitize_shop_domain(@payload['iss'])
    end
  end
endgi
