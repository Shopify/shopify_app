# frozen_string_literal: true

module ShopifyApp
  module Utils
    def self.sanitize_shop_domain(shop_domain)
      myshopify_domain = ShopifyApp.configuration.myshopify_domain
      name = shop_domain.to_s.downcase.strip
      name += ".#{myshopify_domain}" if !name.include?(myshopify_domain.to_s) && !name.include?(".")
      name.sub!(%r|https?://|, "")

      u = URI("http://#{name}")
      u.host if u.host&.match(/^[a-z0-9][a-z0-9\-]*[a-z0-9]\.#{Regexp.escape(myshopify_domain)}$/)
    rescue URI::InvalidURIError
      nil
    end

    def self.shop_login_url(shop:, host:, return_to:)
      return ShopifyApp.configuration.login_url unless shop

      url = URI(ShopifyApp.configuration.login_url)

      url.query = URI.encode_www_form(
        shop: shop,
        host: host,
        return_to: return_to,
      )

      url.to_s
    end

    module Logger
      LOG_LEVELS = { debug: 0, info: 1, warn: 2, error: 3, off: 4 }
      PREFIX = "ShopifyApp"

      def self.send_to_logger(log_level, message)
        return if enabled_for_log_level?(log_level)
        current_shop = ShopifyAPI::Context.active_session&.shop || "Shop Not Found"
        message_context = "[#{Time.current}] [ #{PREFIX} | DEBUG | #{current_shop} ] #{message}"

        ShopifyAPI::Context.logger.send(log_level, message_context + message)
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

      private
      def enabled_for_log_level?(log_level)
        LOG_LEVELS[log_level] <= LOG_LEVELS[ShopifyApp.configuration.log_level]
      end
    end
  end
end
