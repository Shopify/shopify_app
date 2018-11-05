# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :shopify,
           ShopifyApp.configuration.api_key,
           ShopifyApp.configuration.secret,
           scope: ShopifyApp.configuration.scope,
           setup: lambda do |env|
    strategy = env['omniauth.strategy']

    shopify_auth_params = strategy.session['shopify.omniauth_params']&.with_indifferent_access
    shop = shopify_auth_params.present? ? "https://#{shopify_auth_params[:shop]}" : ''

    strategy.options[:client_options][:site] = shop
    strategy.options[:client_options][:old_client_secret] = ENV['SHOPIFY_OLD_CLIENT_SECRET']
  end
end
