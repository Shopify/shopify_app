# frozen_string_literal: true
require 'test_helper'
require 'generators/shopify_app/install/install_generator'

class InstallGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::InstallGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    prepare_destination
    provide_existing_gemfile
    provide_existing_application_file
    provide_existing_routes_file
    provide_existing_application_controller
    provide_development_config_file
  end

  test "creates the ShopifyApp initializer" do
    run_generator
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match 'config.application_name = "My Shopify App"', shopify_app
      assert_match "config.api_key = ENV.fetch('SHOPIFY_API_KEY', '')", shopify_app
      assert_match "config.secret = ENV.fetch('SHOPIFY_API_SECRET', '')", shopify_app
      assert_match 'config.scope = "read_products"', shopify_app
      assert_match "config.embedded_app = true", shopify_app
      assert_match "config.api_version = \"#{ShopifyAPI::LATEST_SUPPORTED_ADMIN_VERSION}\"", shopify_app
      assert_match "config.after_authenticate_job = false", shopify_app

      context_setup = <<~CONTEXT_SETUP
        ShopifyAPI::Context.setup(
          api_key: ShopifyApp.configuration.api_key,
          api_secret_key: ShopifyApp.configuration.secret,
          api_version: ShopifyApp.configuration.api_version,
          host_name: ENV.fetch('SHOPIFY_APP_HOST_NAME', ''),
          scope: ShopifyApp.configuration.scope,
          is_private: !ENV.fetch('SHOPIFY_APP_PRIVATE_SHOP', '').empty?,
          is_embedded: ShopifyApp.configuration.embedded_app,
          session_storage: ShopifyApp::SessionRepository,
          logger: Rails.logger,
          private_shop: ENV.fetch('SHOPIFY_APP_PRIVATE_SHOP', nil),
          user_agent_prefix: "ShopifyApp/\#{ShopifyApp::VERSION}"
        )
      CONTEXT_SETUP

      assert_match context_setup, shopify_app
    end
  end

  test "creates the ShopifyApp initializer with args" do
    run_generator %w(--application_name Test Name
                     --api_version unstable --scope read_orders write_products)
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match 'config.application_name = "Test Name"', shopify_app
      assert_match "config.api_key = ENV.fetch('SHOPIFY_API_KEY', '')", shopify_app
      assert_match "config.secret = ENV.fetch('SHOPIFY_API_SECRET', '')", shopify_app
      assert_match 'config.scope = "read_orders write_products"', shopify_app
      assert_match 'config.embedded_app = true', shopify_app
      assert_match 'config.api_version = "unstable"', shopify_app
      assert_match "config.shop_session_repository = 'Shop'", shopify_app
    end
  end

  test "creates the ShopifyApp initializer with double-quoted args" do
    run_generator %w(--application_name Test Name --scope read_orders write_products)
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match 'config.application_name = "Test Name"', shopify_app
      assert_match "config.api_key = ENV.fetch('SHOPIFY_API_KEY', '')", shopify_app
      assert_match "config.secret = ENV.fetch('SHOPIFY_API_SECRET', '')", shopify_app
      assert_match 'config.scope = "read_orders write_products"', shopify_app
      assert_match 'config.embedded_app = true', shopify_app
      assert_match "config.shop_session_repository = 'Shop'", shopify_app
    end
  end

  test "creates the ShopifyApp initializer for non embedded app" do
    run_generator %w(--embedded false)
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match "config.embedded_app = false", shopify_app
    end
  end

  test "uses cookie based auth strategy for non embedded app" do
    run_generator %w(--embedded false)
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match 'config.allow_jwt_authentication = false', shopify_app
      assert_match 'config.allow_cookie_authentication = true', shopify_app
    end
  end

  test "creates and injects into omniauth initializer" do
    run_generator
    assert_file "config/initializers/omniauth.rb" do |omniauth|
      assert_match "provider :shopify", omniauth
    end
  end

  test "creates the embedded_app layout" do
    run_generator
    assert_file "app/views/layouts/embedded_app.html.erb"
    assert_file "app/views/layouts/_flash_messages.html.erb"
  end

  test "adds engine to routes" do
    run_generator
    assert_file "config/routes.rb" do |routes|
      assert_match "mount ShopifyApp::Engine, at: '/'", routes
    end
  end

  test "adds host config to development.rb" do
    run_generator
    assert_file "config/environments/development.rb" do |config|
      assert_match "config.hosts = (config.hosts rescue []) << /\[-\\w]+\\.ngrok\\.io/", config
    end
  end

  test "enables session token auth and disables cookie auth when --with-cookie-authentication is not set" do
    run_generator
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match "config.embedded_app = true", shopify_app
      assert_match 'config.allow_jwt_authentication = true', shopify_app
      assert_match 'config.allow_cookie_authentication = false', shopify_app
    end
  end

  test "disables session token auth and enables cookie auth when --with-cookie-authentication is set" do
    run_generator %w(--with-cookie-authentication)
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match "config.embedded_app = true", shopify_app
      assert_match 'config.allow_jwt_authentication = false', shopify_app
      assert_match 'config.allow_cookie_authentication = true', shopify_app
    end
  end
end
