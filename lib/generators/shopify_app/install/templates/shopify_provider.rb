# frozen_string_literal: true

provider :shopify,
  ShopifyApp.configuration.api_key,
  ShopifyApp.configuration.secret,
  scope: ShopifyApp.configuration.scope,
  setup: lambda { |env|
    configuration = ShopifyApp::OmniauthConfiguration.new(env['omniauth.strategy'], Rack::Request.new(env))
    configuration.build_options
  }
