# frozen_string_literal: true

module ShopifyApp
  class JWT
    class InvalidDestinationError < StandardError; end

    class MismatchedHostsError < StandardError; end

    class InvalidAudienceError < StandardError; end

    NBF_TOLERANCE = 5.seconds

    WARN_EXCEPTIONS = [
      ::JWT::DecodeError,
      ::JWT::ExpiredSignature,
      ::JWT::ImmatureSignature,
      ::JWT::VerificationError,
      InvalidAudienceError,
      InvalidDestinationError,
      MismatchedHostsError,
    ]

    def initialize(token)
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
    rescue *WARN_EXCEPTIONS => error
      Rails.logger.warn("[ShopifyApp::JWT] Failed to validate JWT: [#{error.class}] #{error}")
      nil
    end

    def parse_token_data(secret, old_secret)
      ::JWT.decode(@token, secret, true, { nbf_leeway: NBF_TOLERANCE, algorithm: "HS256" })
    rescue ::JWT::VerificationError
      raise unless old_secret

      ::JWT.decode(@token, old_secret, true, { algorithm: "HS256" })
    end

    def validate_payload(payload)
      dest_host = ShopifyApp::Utils.sanitize_shop_domain(payload["dest"])
      iss_host = ShopifyApp::Utils.sanitize_shop_domain(payload["iss"])
      api_key = ShopifyApp.configuration.api_key

      raise InvalidAudienceError, "'aud' claim does not match api_key" unless payload["aud"] == api_key
      raise InvalidDestinationError, "'dest' claim host not a valid shopify host" unless dest_host
      raise MismatchedHostsError, "'dest' claim host does not match 'iss' claim host" unless dest_host == iss_host

      payload
    end
  end
end
