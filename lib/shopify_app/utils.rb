module ShopifyApp
  module Utils

    def self.sanitize_shop_domain(shop_domain)
      name = shop_domain.to_s.strip
      name += ".#{ShopifyApp.configuration.myshopify_domain}" if !name.include?("#{ShopifyApp.configuration.myshopify_domain}") && !name.include?(".")
      name.sub!(%r|https?://|, '')

      u = URI("http://#{name}")
      u.host && u.host.ends_with?(".#{ShopifyApp.configuration.myshopify_domain}") ? u.host : nil
    rescue URI::InvalidURIError
      nil
    end

  end
end
