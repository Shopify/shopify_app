# frozen_string_literal: true

module ShopifyApp
  module Utils
    class << self
      TRUSTED_SHOPIFY_DOMAINS = [
        "shopify.com",
        "myshopify.io",
        "myshopify.com",
        "spin.dev",
      ].freeze

      def sanitize_shop_domain(shop_domain)
        uri = uri_from_shop_domain(shop_domain)
        return nil if uri.nil? || uri.host.nil?

        trusted_domains.each do |trusted_domain|
          no_shop_name_in_subdomain = uri.host == trusted_domain
          from_trusted_domain = trusted_domain == uri.domain

          return myshopify_domain_from_unified_admin(uri) if unified_admin?(uri) && from_trusted_domain
          return nil if no_shop_name_in_subdomain || uri.host&.empty?
          return uri.host if from_trusted_domain
        end
        nil
      end

      def shop_login_url(shop:, host:, return_to:)
        return ShopifyApp.configuration.login_url unless shop

        url = URI(ShopifyApp.configuration.login_url)

        url.query = URI.encode_www_form(
          shop: shop,
          host: host,
          return_to: return_to,
        )

        url.to_s
      end

      def unified_admin_path(shop)
        spin_env = ENV.fetch("SPIN_FQDN", nil)
        if spin_env
          "https://admin.web.#{spin_env}/store/#{shop}"
        else
          "https://admin.#{unified_admin_domain}/store/#{shop}"
        end
      end

      private

      def myshopify_domain
        ShopifyApp.configuration.myshopify_domain
      end

      def unified_admin_domain
        ShopifyApp.configuration.unified_admin_domain
      end

      def trusted_domains
        trusted_domains = TRUSTED_SHOPIFY_DOMAINS.dup
        trusted_domains.append(myshopify_domain).uniq! if myshopify_domain
        trusted_domains
      end

      def uri_from_shop_domain(shop_domain)
        name = shop_domain.to_s.downcase.strip
        name += ".#{myshopify_domain}" if !name.include?(myshopify_domain.to_s) && !name.include?(".")
        uri = Addressable::URI.parse(name)

        if uri.scheme.nil?
          name = "https://" + name
          uri = Addressable::URI.parse(name)
        end

        uri
      rescue Addressable::URI::InvalidURIError
        nil
      end

      def unified_admin?(uri)
        uri.host.split(".").first == "admin"
      end

      def myshopify_domain_from_unified_admin(uri)
        shop = uri.path.split("/").last

        "#{shop}.myshopify.com"
      end
    end
  end
end
