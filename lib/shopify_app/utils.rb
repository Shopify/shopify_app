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

    def self.logger_debug(message)
      current_shop = ShopifyAPI::Context.active_session&.shop
      if ShopifyApp.configuration.log_level == :debug
        ShopifyAPI::Context.logger.debug("[#{DateTime.current}] [ Shopify | DEBUG | #{current_shop} ] #{message}")
      end
    end

    def self.logger_info(message)
      current_shop = ShopifyAPI::Context.active_session&.shop
      if ShopifyApp.configuration.log_level == :info
        ShopifyAPI::Context.logger.info("[#{DateTime.current}] [ Shopify | INFO | #{current_shop} ] #{message}")
      end
    end
  end
end
