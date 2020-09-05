# frozen_string_literal: true
module ShopifyApp
  module SessionStorage
    extend ActiveSupport::Concern

    included do
      validates :shopify_token, presence: true, unless: :shopify_token_nillable?
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
    
    protected
    
    def shopify_token_nillable?
      false
    end
  end
end
