require 'test_helper'
require 'generators/shopify_app/enable_after_install_actions/enable_after_install_actions_generator'

class EnableAfterInstallActionsGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::EnableAfterInstallActionsGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    prepare_destination
  end

  test 'adds after_install config' do
    provide_existing_initializer_file

    run_generator

    assert_file "config/initializers/shopify_app.rb" do |config|
      assert_match 'config.enable_after_install_actions = true', config
    end
  end

  test "adds the after_install job" do
    provide_existing_initializer_file

    run_generator

    assert_directory "app/jobs/shopify"
    assert_file "app/jobs/shopify/after_install_job.rb"
  end
end
