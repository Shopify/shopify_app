# frozen_string_literal: true

module ShopifyApp
  module Utils
    TRUSTED_SHOPIFY_DOMAINS = [
      "shopify.com",
      "shopify.io",
      "myshopify.com",
    ].freeze

    def self.sanitize_shop_domain(shop_domain)
      myshopify_domain = ShopifyApp.configuration.myshopify_domain
      name = shop_domain.to_s.downcase.strip
      name += ".#{myshopify_domain}" if !name.include?(myshopify_domain.to_s) && !name.include?(".")
      name.sub!(%r|https?://|, "")
      trusted_domains = TRUSTED_SHOPIFY_DOMAINS.dup.push(myshopify_domain)

      u = URI("http://#{name}")
      regex = /^[a-z0-9][a-z0-9\-]*[a-z0-9]\.(#{trusted_domains.join("|")})$/
      u.host if u.host&.match(regex)
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
  end
end
