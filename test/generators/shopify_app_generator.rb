require 'test_helper'
require 'generators/shopify_app/shopify_app_generator'

class ViewsGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::ViewsGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))
  setup :prepare_destination

  test "copies ShopifyApp views to the host application" do
    run_generator
    assert_directory "app/views"
    assert_file "app/views/sessions/new.html.erb"
  end

end
