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

    def self.fetch_known_api_versions
      Rails.logger.info("[ShopifyAPI::ApiVersion] Fetching known Admin API Versions from Shopify...")
      ShopifyAPI::ApiVersion.fetch_known_versions
      Rails.logger.info("[ShopifyAPI::ApiVersion] Known API Versions: #{ShopifyAPI::ApiVersion.versions.keys}")
    rescue ActiveResource::ConnectionError
      logger.error("[ShopifyAPI::ApiVersion] Unable to fetch api_versions from Shopify")
    end

    def self.shop_login_url(shop:, return_to:)
      return ShopifyApp.configuration.login_url unless shop
      url = URI(ShopifyApp.configuration.login_url)

      url.query = URI.encode_www_form(
        shop: shop,
        return_to: return_to,
      )

      url.to_s
    end
  end
end
