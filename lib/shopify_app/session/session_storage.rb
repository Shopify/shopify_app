module ShopifyApp
  module SessionStorage
    extend ActiveSupport::Concern

    class_methods do
      def storage_strategy=(strategy)
        @strategy = strategy
      end

      def storage_strategy
        @strategy ||= begin
          if ShopifyApp.configuration.per_user_tokens?
            ShopifyApp::SessionStorage::UserStorageStrategy.new(self)
          else
            ShopifyApp::SessionStorage::ShopStorageStrategy.new(self)
          end
        end
      end

      delegate :store, :retrieve, to: :storage_strategy
    end

    included do
      validates :shopify_token, presence: true
      validates :api_version, presence: true
      validates :shopify_domain, presence: true,
        if: Proc.new {|_| ShopifyApp.configuration.per_user_tokens? }
      validates :shopify_domain, presence: true, uniqueness: { case_sensitive: false },
        if: Proc.new {|_| !ShopifyApp.configuration.per_user_tokens? }
    end

    def with_shopify_session(&block)
      ShopifyAPI::Session.temp(
        domain: shopify_domain,
        token: shopify_token,
        api_version: api_version,
        &block
      )
    end
  end
end
