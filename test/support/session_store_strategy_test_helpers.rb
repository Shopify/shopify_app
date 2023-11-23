# frozen_string_literal: true

module SessionStoreStrategyTestHelpers
  class MockShopInstance
    attr_reader :id, :shopify_domain, :shopify_token, :api_version, :access_scopes
    attr_writer :shopify_token, :access_scopes

    def initialize(
      id: 1,
      shopify_domain: "example.myshopify.com",
      shopify_token: "abcd-shop-token",
      api_version: ShopifyApp.configuration.api_version,
      scopes: "read_products"
    )
      @id = id
      @shopify_domain = shopify_domain
      @shopify_token = shopify_token
      @api_version = api_version
      @access_scopes = scopes
    end
  end

  class MockUserInstance
    attr_reader :id, :shopify_user_id, :shopify_domain, :shopify_token, :api_version, :access_scopes, :expires_at
    attr_writer :shopify_token, :shopify_domain, :access_scopes, :expires_at

    def initialize(
      id: 1,
      shopify_user_id: 1,
      shopify_domain: "example.myshopify.com",
      shopify_token: "1234-user-token",
      api_version: ShopifyApp.configuration.api_version,
      scopes: "read_products",
      expires_at: nil
    )
      @id = id
      @shopify_user_id = shopify_user_id
      @shopify_domain = shopify_domain
      @shopify_token = shopify_token
      @api_version = api_version
      @access_scopes = scopes
      @expires_at = expires_at
    end
  end
end
