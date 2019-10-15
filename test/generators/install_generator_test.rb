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

  teardown do
    ShopifyAPI::ApiVersion.clear_known_versions
  end

  test "creates the ShopifyApp initializer" do
    run_generator
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match 'config.application_name = "My Shopify App"', shopify_app
      assert_match "config.api_key = ENV['SHOPIFY_API_KEY']", shopify_app
      assert_match "config.secret = ENV['SHOPIFY_API_SECRET']", shopify_app
      assert_match 'config.scope = "read_products"', shopify_app
      assert_match "config.embedded_app = true", shopify_app
      assert_match 'config.api_version = "2019-10"', shopify_app
      assert_match "config.after_authenticate_job = false", shopify_app
      assert_match "# ShopifyApp::Utils.fetch_known_api_versions", shopify_app
      assert_match "# ShopifyAPI::ApiVersion.version_lookup_mode = :raise_on_unknown ", shopify_app
    end
  end

  test "creates the ShopifyApp initializer with args" do
    run_generator %w(--application_name Test Name --api_key key --secret shhhhh --api_version unstable --scope read_orders, write_products)
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match 'config.application_name = "Test Name"', shopify_app
      assert_match "config.api_key = ENV['SHOPIFY_API_KEY']", shopify_app
      assert_match "config.secret = ENV['SHOPIFY_API_SECRET']", shopify_app
      assert_match 'config.scope = "read_orders, write_products"', shopify_app
      assert_match 'config.embedded_app = true', shopify_app
      assert_match 'config.api_version = "unstable"', shopify_app
      assert_match 'config.session_repository = ShopifyApp::InMemorySessionStore', shopify_app
    end
  end

  test "creates the ShopifyApp initializer with double-quoted args" do
    run_generator %w(--application_name "Test Name" --api_key key --secret shhhhh --scope "read_orders, write_products")
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match 'config.application_name = "Test Name"', shopify_app
      assert_match "config.api_key = ENV['SHOPIFY_API_KEY']", shopify_app
      assert_match "config.secret = ENV['SHOPIFY_API_SECRET']", shopify_app
      assert_match 'config.scope = "read_orders, write_products"', shopify_app
      assert_match 'config.embedded_app = true', shopify_app
      assert_match 'config.session_repository = ShopifyApp::InMemorySessionStore', shopify_app
    end
  end

  test "creates the ShopifyApp initializer for non embedded app" do
    run_generator %w(--embedded false)
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match "config.embedded_app = false", shopify_app
    end
  end

  test "creats and injects into omniauth initializer" do
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

  test "adds dotenv gem to Gemfile" do
    run_generator
    assert_file "Gemfile" do |gemfile|
      assert_match "gem 'dotenv-rails', group: [:test, :development]", gemfile
    end
  end

  test "adds host config to development.rb" do
    run_generator
    assert_file "config/environments/development.rb" do |config|
      assert_match "config.hosts << /\\h+.ngrok.io/", config
    end
  end
end
