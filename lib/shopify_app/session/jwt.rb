module ShopifyApp
  class JWT
    def initialize(token)
      @token = token
      parse_token_data
    end

    def payload
      return unless @payload
      return unless dest_host
      return unless dest_host == iss_host
      return unless @payload['aud'] == ShopifyApp.configuration.api_key

      @payload
    end

    private

    def parse_token_data
      @payload, _ = ::JWT.decode(@token, ShopifyApp.configuration.secret, true, { algorithm: 'HS256' })
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
