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
    assert_file "config/initializers/shopify_app.rb"
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
    stub_embedded_false
    run_generator
    assert_file "config/application.rb" do |application|
      refute_match "config.action_dispatch.default_headers.delete('X-Frame-Options')", application
      refute_match "config.action_dispatch.default_headers['P3P'] = 'CP=\"Not used\"'", application
    end
  end

  test "injects into application controller" do
    run_generator
    assert_file "app/controllers/application_controller.rb" do |controller|
      assert_match "  include ShopifyApp::Controller\n", controller
    end
  end

  test "creates the embedded_app layout" do
    run_generator
    assert_file "app/views/layouts/embedded_app.html.erb"
  end

  test "creates the home controller" do
    run_generator
    assert_file "app/controllers/home_controller.rb"
  end

  test "creates the home index view with embedded options" do
    run_generator
    assert_file "app/views/home/index.html.erb" do |index|
      assert_match "ShopifyApp.ready", index
    end
  end

  test "creates the home index view with embedded false" do
    stub_embedded_false
    run_generator
    assert_file "app/views/home/index.html.erb" do |index|
      refute_match "ShopifyApp.ready", index
    end
  end

  test "adds home route to routes" do
    run_generator
    assert_file "config/routes.rb" do |routes|
      assert_match "root :to => 'home#index'", routes
    end
  end

  private

  def stub_embedded_false
    ShopifyApp::Generators::InstallGenerator.any_instance.stubs(:embedded_app?).returns(false)
  end

end
