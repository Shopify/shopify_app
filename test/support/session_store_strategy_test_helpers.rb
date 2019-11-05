module SessionStoreStrategyTestHelpers

    class MockSessionStore < ActiveRecord::Base
        include ShopifyApp::SessionStorage
      end
      
    class MockShopInstance
        attr_reader :id, :shopify_domain, :shopify_token, :api_version
        
        def initialize(id:1, shopify_domain:'example.myshopify.com', shopify_token:'1234abcd', api_version:'unstable')
            @id = id
            @shopify_domain = shopify_domain
            @shopify_token = shopify_token
            @api_version = api_version
        end
    end
end