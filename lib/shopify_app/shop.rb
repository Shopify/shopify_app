module ShopifyApp
  module Shop
    extend ActiveSupport::Concern

    included do
      validates :shopify_domain, presence: true, uniqueness: true
      if shopify_token_needs_to_exist?
        validates :shopify_token, presence: true
      end
    end

    def with_shopify_session(&block)
      ShopifyAPI::Session.temp(shopify_domain, shopify_token, &block)
    end

    module ClassMethods
      def shopify_token_needs_to_exist?
        true
      end
    end

  end
end
