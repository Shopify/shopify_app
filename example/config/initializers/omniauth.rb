Rails.application.config.middleware.use OmniAuth::Builder do
  provider :shopify,
    ShopifyApp.configuration.api_key,
    ShopifyApp.configuration.secret,
    redirect_uri: ShopifyApp.configuration.redirect_uri,
    scope: ShopifyApp.configuration.scope
end
