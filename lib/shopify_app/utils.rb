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
      LOG_LEVELS = { :debug => 0, :info => 1, :warn => 2, :error => 3, :off => 4 }

      def self.debug(message)
        current_shop = ShopifyAPI::Context.active_session&.shop || "Shop Not Found"
        current_level = LOG_LEVELS[ShopifyApp.configuration.log_level]

        if current_level <= LOG_LEVELS[:debug]
          ShopifyAPI::Context.logger.debug("[#{DateTime.current}] [ Shopify | DEBUG | #{current_shop} ] #{message}")
        end
      end

      def self.info(message)
        current_shop = ShopifyAPI::Context.active_session&.shop || "Shop Not Found"
        current_level = LOG_LEVELS[ShopifyApp.configuration.log_level]

        if current_level >= LOG_LEVELS[:info]
          ShopifyAPI::Context.logger.info("[#{DateTime.current}] [ Shopify | INFO | #{current_shop} ] #{message}")
        end
      end

      def self.warn(message)
        current_shop = ShopifyAPI::Context.active_session&.shop || "Shop Not Found"
        current_level = LOG_LEVELS[ShopifyApp.configuration.log_level]

        if current_level >= LOG_LEVELS[:warn]
          ShopifyAPI::Context.logger.info("[#{DateTime.current}] [ Shopify | WARNING | #{current_shop} ] #{message}")
        end
      end

      def self.error(message)
        current_shop = ShopifyAPI::Context.active_session&.shop || "Shop Not Found"
        current_level = LOG_LEVELS[ShopifyApp.configuration.log_level]

        if current_level >= LOG_LEVELS[:error]
          ShopifyAPI::Context.logger.debug("[#{DateTime.current}] [ Shopify | ERROR | #{current_shop} ] #{message}")
        end
      end
    end
  end
end
