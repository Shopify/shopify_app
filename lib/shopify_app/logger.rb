# frozen_string_literal: true

module ShopifyApp
  class Logger < ShopifyAPI::Logger
    def self.deprecated(message, version)
      return unless enabled_for_log_level?(:warn)

      raise StandardError unless ShopifyApp::VERSION < version

      ActiveSupport::Deprecation.warn("[#{version}] #{context(:warn)} #{message}")
    end
  end
end
