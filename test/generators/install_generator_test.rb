require 'test_helper'
require 'generators/shopify_app/install/install_generator'

class InstallGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::InstallGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    prepare_destination
    provide_existing_application_file
    provide_existing_routes_file
    provide_existing_application_controller
  end

  test "creates the ShopifyApp initializer" do
    run_generator
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match 'config.api_key = "<api_key>"', shopify_app
      assert_match 'config.secret = "<secret>"', shopify_app
      assert_match 'config.scope = "read_orders, read_products"', shopify_app
      assert_match "config.embedded_app = true", shopify_app
    end
  end

  test "creates the ShopifyApp initializer with args" do
    run_generator %w(--application_name Test Name --api_key key --secret shhhhh --scope read_orders, write_products)
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match 'config.application_name = "Test Name"', shopify_app
      assert_match 'config.api_key = "key"', shopify_app
      assert_match 'config.secret = "shhhhh"', shopify_app
      assert_match 'config.scope = "read_orders, write_products"', shopify_app
      assert_match "config.embedded_app = true", shopify_app
    end
  end

  test "creates the ShopifyApp initializer with double-quoted args" do
    run_generator %w(--application_name "Test Name" --api_key key --secret shhhhh --scope "read_orders, write_products")
    assert_file "config/initializers/shopify_app.rb" do |shopify_app|
      assert_match 'config.application_name = "Test Name"', shopify_app
      assert_match 'config.api_key = "key"', shopify_app
      assert_match 'config.secret = "shhhhh"', shopify_app
      assert_match 'config.scope = "read_orders, write_products"', shopify_app
      assert_match "config.embedded_app = true", shopify_app
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

  test "creates the default shopify_session_repository" do
    run_generator
    assert_file "config/initializers/shopify_session_repository.rb" do |file|
      assert_match "ShopifyApp::SessionRepository.storage = InMemorySessionStore", file
    end
  end

  test "adds the embedded app options to application.rb" do
    run_generator
    assert_file "config/application.rb" do |application|
      assert_match "config.action_dispatch.default_headers.delete('X-Frame-Options')", application
      assert_match "config.action_dispatch.default_headers['P3P'] = 'CP=\"Not used\"'", application
    end
  end

  test "doesn't add embedd options if -embedded false" do
    run_generator %w(--embedded false)
    assert_file "config/application.rb" do |application|
      refute_match "config.action_dispatch.default_headers.delete('X-Frame-Options')", application
      refute_match "config.action_dispatch.default_headers['P3P'] = 'CP=\"Not used\"'", application
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
end
