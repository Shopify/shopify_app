# frozen_string_literal: true

module ShopifyApp
  class Logger < ShopifyAPI::Logger
    class << self
      def deprecated(message, version)
        return unless enabled_for_log_level?(:warn)

        raise ShopifyAPI::Errors::FeatureDeprecatedError unless valid_version(version)

        ActiveSupport::Deprecation.warn("[#{version}] #{context(:warn)} #{message}")
      end

      private

      def context(log_level)
        current_shop = ShopifyAPI::Context.active_session&.shop || "Shop Not Found"
        "[ ShopifyApp | #{log_level.to_s.upcase} | #{current_shop} ]"
      end

      def valid_version(version)
        current_version = Gem::Version.create(ShopifyApp::VERSION)
        deprecate_version = Gem::Version.create(version)
        current_version < deprecate_version
      end
    end
  end
end
