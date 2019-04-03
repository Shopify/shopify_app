module ShopifyApp
  module SessionStorage
    extend ActiveSupport::Concern

    included do
      validates :shopify_domain, presence: true, uniqueness: { case_sensitive: false }
      validates :shopify_token, presence: true
      validates :api_version, presence: true
    end

    def with_shopify_session(&block)
      ShopifyAPI::Session.temp(
        domain: shopify_domain,
        token: shopify_token,
        api_version: api_version,
        &block
      )
    end

    class_methods do
      def store(session)
        shop = find_or_initialize_by(shopify_domain: session.domain)
        shop.shopify_token = session.token
        shop.save!
        shop.id
      end

      def retrieve(id)
        return unless id

        if shop = self.find_by(id: id)
          ShopifyAPI::Session.new(
            domain: shop.shopify_domain,
            token: shop.shopify_token,
            api_version: shop.api_version
          )
        end
      end
    end
  end
end
