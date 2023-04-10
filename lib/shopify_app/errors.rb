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
end
