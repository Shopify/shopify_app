# frozen_string_literal: true

module ShopifyApp
  module Utils
    TRUSTED_SHOPIFY_DOMAINS = [
      "shopify.com",
      "myshopify.io",
      "myshopify.com",
      "spin.dev"
    ].freeze

    def self.sanitize_shop_domain(shop_domain)
      myshopify_domain = ShopifyApp.configuration.myshopify_domain
      name = shop_domain.to_s.downcase.strip
      name = "https://" + name unless name.include?("http")
      name += ".#{myshopify_domain}" if !name.include?(myshopify_domain.to_s) && !name.include?(".")
      uri = Addressable::URI.parse(name)

      trusted_domains = TRUSTED_SHOPIFY_DOMAINS.dup
      trusted_domains.push(myshopify_domain) if myshopify_domain

      if trusted_domains.any? { |trusted_domain| trusted_domain == uri.domain}
        return uri.host
      else
        return nil
      end
    rescue Addressable::URI::InvalidURIError
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
