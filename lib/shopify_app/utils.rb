module ShopifyApp
  module Utils

    def self.sanitize_shop_domain(shop_domain)
      name = shop_domain.to_s.strip
      name += ".#{ShopifyApp.configuration.myshopify_domain}" if !name.include?("#{ShopifyApp.configuration.myshopify_domain}") && !name.include?(".")
      name.sub!(%r|https?://|, '')

      u = URI("http://#{name}")
      u.host if u.host&.match(/^[a-z0-9][a-z0-9\-]*[a-z0-9]\.#{Regexp.escape(ShopifyApp.configuration.myshopify_domain)}$/)
    rescue URI::InvalidURIError
      nil
    end

  end
end
