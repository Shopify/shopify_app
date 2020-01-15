module ShopifyApp
  module SessionStorage
    extend ActiveSupport::Concern

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

    class_methods do

      def strategy_klass
        ShopifyApp.configuration.per_user_tokens? ? 
          ShopifyApp::SessionStorage::UserStorageStrategy : 
          ShopifyApp::SessionStorage::ShopStorageStrategy
      end

      def store(auth_session, user: nil)
        strategy_klass.store(auth_session, user)
      end

      def retrieve(id)
        strategy_klass.retrieve(id)
      end
    end
  end
end
