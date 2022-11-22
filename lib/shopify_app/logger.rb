# frozen_string_literal: true

module ShopifyApp
  class Logger < ShopifyAPI::Logger
    def self.deprecated(message, version)
      return unless enabled_for_log_level?(:warn)

      raise ShopifyAPI::Errors::FeatureDeprecatedError unless ShopifyApp::VERSION < version

      ActiveSupport::Deprecation.warn("[#{version}] #{context(:warn)} #{message}")
    end

    def self.context(log_level)
      current_shop = ShopifyAPI::Context.active_session&.shop || "Shop Not Found"
      "[ ShopifyApp | #{log_level.to_s.upcase} | #{current_shop} ]"
    end
  end
end
