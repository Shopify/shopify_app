# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/generators/shopify_app/add_app_uninstalled_job/add_app_uninstalled_job_generator"

class AddAppUninstalledJobGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::AddAppUninstalledJobGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))

  setup do
    ShopifyApp.configure do |config|
      config.embedded_app = true
    end

    prepare_destination
    provide_existing_application_file
    provide_existing_routes_file
    provide_existing_application_controller
  end

  test "creates app uninstalled job file" do
    run_generator

    assert_file "app/jobs/app_uninstalled_job.rb" do |job|
      assert_match "extend ShopifyAPI::Webhooks::WebhookHandler", job
      assert_match "def self.handle(data:)", job
      assert_match "perform_later(topic: data.topic, shop_domain: data.shop, webhook: data.body)", job
    end
  end
end
