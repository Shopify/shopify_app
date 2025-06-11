# frozen_string_literal: true

module ShopifyApp
  class BillingError < StandardError
    attr_accessor :message
    attr_accessor :errors

    def initialize(message, errors)
      super(message)
      @message = message
      @errors = errors
    end
  end

  class ConfigurationError < StandardError; end

  class CreationFailed < StandardError; end

  class EnvironmentError < StandardError; end

  class InvalidAudienceError < StandardError; end

  class InvalidDestinationError < StandardError; end

  class InvalidInput < StandardError; end

  class MismatchedHostsError < StandardError; end

  class MissingWebhookJobError < StandardError; end

  class ShopifyDomainNotFound < StandardError; end

  class ShopifyHostNotFound < StandardError; end

  module Errors
    class ShopifyAppError < StandardError; end

    # JWT Token Errors
    class MissingJwtTokenError < ShopifyAppError
      def initialize(message = "JWT token is missing")
        super
      end
    end

    class InvalidJwtTokenError < ShopifyAppError
      def initialize(message = "JWT token is invalid")
        super
      end
    end

    # HTTP Response Errors
    class HttpResponseError < ShopifyAppError
      attr_reader :response

      def initialize(response:, message: nil)
        @response = response
        super(message || "HTTP request failed with status #{response[:status]}")
      end
    end

    # Session Errors
    class SessionNotFoundError < ShopifyAppError; end
    class InvalidSessionError < ShopifyAppError; end

    # Token Exchange Errors
    class TokenExchangeError < ShopifyAppError; end
    class MissingShopDomainError < ShopifyAppError; end
  end
end
