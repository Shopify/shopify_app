# frozen_string_literal: true
module SessionStoreStrategyTestHelpers
  class MockShopInstance
    attr_reader :id, :shopify_domain, :shopify_token, :api_version
    attr_writer :shopify_token
    def initialize(id: 1, shopify_domain: 'example.myshopify.com',
                   shopify_token: 'abcd-shop-token', api_version: 'unstable')
      @id = id
      @shopify_domain = shopify_domain
      @shopify_token = shopify_token
      @api_version = api_version
    end
  end

  class MockUserInstance
    attr_reader :id, :shopify_user_id, :shopify_domain, :shopify_token, :api_version
    attr_writer :shopify_token, :shopify_domain

    def initialize(id: 1, shopify_user_id: 1, shopify_domain: 'example.myshopify.com',
                   shopify_token: '1234-user-token', api_version: 'unstable')
      @id = id
      @shopify_user_id = shopify_user_id
      @shopify_domain = shopify_domain
      @shopify_token = shopify_token
      @api_version = api_version
    end
  end
end
