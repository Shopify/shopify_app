module ShopifyApp
  class JWT
    def initialize(token)
      @token = token
      set_payload
    end

    def payload
      return unless @payload
      return unless dest_host
      return unless dest_host == iss_host
      return unless @payload['aud'] == ShopifyApp.configuration.api_key

      @payload
    end

    private

    def set_payload
      parse_token_data(ShopifyApp.configuration.secret)
      parse_token_data(ShopifyApp.configuration.old_secret) if !@payload && ShopifyApp.configuration.old_secret
    end

    def parse_token_data(secret)
      @payload, _ = ::JWT.decode(@token, secret, true, { algorithm: 'HS256' })
    rescue ::JWT::DecodeError, ::JWT::VerificationError, ::JWT::ExpiredSignature, ::JWT::ImmatureSignature
      @payload = nil
    end

    def dest_host
      @payload && ShopifyApp::Utils.sanitize_shop_domain(@payload['dest'])
    end

    def iss_host
      @payload && ShopifyApp::Utils.sanitize_shop_domain(@payload['iss'])
    end
  end
end
