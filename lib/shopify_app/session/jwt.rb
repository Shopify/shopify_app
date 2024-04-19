# frozen_string_literal: true

module ShopifyApp
  class JWT
    WARN_EXCEPTIONS = [
      ::JWT::DecodeError,
      ::JWT::ExpiredSignature,
      ::JWT::ImmatureSignature,
      ::JWT::VerificationError,
      ::ShopifyApp::InvalidAudienceError,
      ::ShopifyApp::InvalidDestinationError,
      ::ShopifyApp::MismatchedHostsError,
    ]

    def initialize(token)
      warn_deprecation
      @token = token
      set_payload
    end

    def shopify_domain
      @payload && ShopifyApp::Utils.sanitize_shop_domain(@payload["dest"])
    end

    def shopify_user_id
      @payload["sub"].to_i if @payload && @payload["sub"]
    end

    def expire_at
      @payload["exp"].to_i if @payload && @payload["exp"]
    end

    private

    def set_payload
      payload, _ = parse_token_data(ShopifyApp.configuration&.secret, ShopifyApp.configuration&.old_secret)
      @payload = validate_payload(payload)
    rescue *WARN_EXCEPTIONS
      nil
    end

    def parse_token_data(secret, old_secret)
      ::JWT.decode(@token, secret, true, { algorithm: "HS256" })
    rescue ::JWT::VerificationError
      raise unless old_secret

      ::JWT.decode(@token, old_secret, true, { algorithm: "HS256" })
    end

    def validate_payload(payload)
      dest_host = ShopifyApp::Utils.sanitize_shop_domain(payload["dest"])
      iss_host = ShopifyApp::Utils.sanitize_shop_domain(payload["iss"])
      api_key = ShopifyApp.configuration.api_key

      raise ::ShopifyApp::InvalidAudienceError,
        "'aud' claim does not match api_key" unless payload["aud"] == api_key
      raise ::ShopifyApp::InvalidDestinationError, "'dest' claim host not a valid shopify host" unless dest_host

      raise ::ShopifyApp::MismatchedHostsError,
        "'dest' claim host does not match 'iss' claim host" unless dest_host == iss_host

      payload
    end

    def warn_deprecation
      message = <<~EOS
        "ShopifyApp::JWT will be deprecated, use ShopifyAPI::Auth::JwtPayload to parse JWT token instead."
      EOS

      ShopifyApp::Logger.deprecated(message, "23.0.0")
    end
  end
end
