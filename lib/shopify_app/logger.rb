# frozen_string_literal: true

module ShopifyApp
  module Logger
    LOG_LEVELS = { debug: 0, info: 1, warn: 2, error: 3, off: 6 }
    DEFAULT_LOG_LEVEL = :info

    def self.send_to_logger(log_level, message)
      return unless enabled_for_log_level?(log_level)

      full_message = "#{context(log_level)} #{message}"

      ShopifyAPI::Context.logger.send(log_level, full_message)
    end

    def self.debug(message)
      send_to_logger(:debug, message)
    end

    def self.info(message)
      send_to_logger(:info, message)
    end

    def self.warn(message)
      send_to_logger(:warn, message)
    end

    def self.error(message)
      send_to_logger(:error, message)
    end

    def self.deprecated(message)
      return unless enabled_for_log_level?(:warn)

      ActiveSupport::Deprecation.warn("#{context(:warn)} #{message}")
    end

    def self.context(log_level)
      current_shop = ShopifyAPI::Context.active_session&.shop || "Shop Not Found"
      "[ ShopifyApp | #{log_level.to_s.upcase} | #{current_shop} ]"
    end

    def self.enabled_for_log_level?(log_level)
      raise(ShopifyApp::ConfigurationError,
        "Invalid Log Level - #{log_level}") unless LOG_LEVELS.keys.include?(log_level)

      LOG_LEVELS[log_level] >= LOG_LEVELS[ShopifyApp.configuration.log_level || DEFAULT_LOG_LEVEL]
    end
  end
end
