# frozen_string_literal: true

provider :shopify,
  ShopifyApp.configuration.api_key,
  ShopifyApp.configuration.secret,
  scope: ShopifyApp.configuration.scope,
  per_user_permissions: ShopifyApp.configuration.user_session_repository.present?,
  setup: lambda { |env|
    strategy = env['omniauth.strategy']

    shopify_auth_params = strategy.session['shopify.omniauth_params']&.with_indifferent_access
    shop = if shopify_auth_params.present?
      "https://#{shopify_auth_params[:shop]}"
    else
      ''
    end

    strategy.options[:client_options][:site] = shop
    strategy.options[:old_client_secret] = ShopifyApp.configuration.old_secret
  }
