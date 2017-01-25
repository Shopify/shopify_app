Rails.application.config.middleware.use OmniAuth::Builder do

  provider :shopify,
    ShopifyApp.configuration.api_key,
    ShopifyApp.configuration.secret,
    scope: ShopifyApp.configuration.scope,
    myshopify_domain: ShopifyApp.configuration.myshopify_domain
end
