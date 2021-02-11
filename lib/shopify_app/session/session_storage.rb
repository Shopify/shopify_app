# frozen_string_literal: true
module ShopifyApp
  module SessionStorage
    extend ActiveSupport::Concern

    included do
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

    def access_scopes=(scopes)
      super(scopes)
    rescue NotImplementedError
      Rails.logger.warn("#scopes= must be overriden to handle storing scopes: #{scopes}")
    end

    def access_scopes
      super
    rescue NotImplementedError
      raise NotImplementedError, "#scopes must be defined to hook into stored scopes"
    end
  end
end
