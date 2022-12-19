# frozen_string_literal: true

module ShopifyApp
  module Utils
    TRUSTED_SHOPIFY_DOMAINS = [
      "shopify.com",
      "myshopify.io",
      "myshopify.com",
      "spin.dev",
    ].freeze

    def self.sanitize_shop_domain(shop_domain)
      myshopify_domain = ShopifyApp.configuration.myshopify_domain
      name = shop_domain.to_s.downcase.strip
      name = "https://" + name unless name.include?("http")
      name += ".#{myshopify_domain}" if !name.include?(myshopify_domain.to_s) && !name.include?(".")
      uri = Addressable::URI.parse(name)

      trusted_domains = TRUSTED_SHOPIFY_DOMAINS.dup
      trusted_domains.append(myshopify_domain).uniq! if myshopify_domain

      trusted_domains.each do |trusted_domain|
        no_shop_name_in_subdomain = uri.host == trusted_domain
        from_trusted_domain = trusted_domain == uri.domain

        return nil if no_shop_name_in_subdomain || uri.host.empty?
        return uri.host if from_trusted_domain
      end

      nil
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
