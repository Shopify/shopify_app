# typed: false
require 'test_helper'
require 'generators/shopify_app/add_webhook/add_webhook_generator'

class AddWebhookGeneratorTest < Rails::Generators::TestCase
  tests ShopifyApp::Generators::AddWebhookGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))
  arguments %w(-t products/update -a https://example.com/webhooks/product_update)

  setup do
    prepare_destination
  end

  test "adds new webhook to config without exisiting webhooks" do
    provide_existing_initializer_file

    run_generator

    assert_file "config/initializers/shopify_app.rb" do |config|
      assert_match 'config.webhooks = [', config
      assert_match new_webhook, config
    end
  end

  test "adds new webhook to config exisiting webhooks" do
    provide_existing_initializer_file_with_webhooks

    run_generator

    assert_file "config/initializers/shopify_app.rb" do |config|
      assert_match 'config.webhooks = [', config
      assert_match exisiting_webhook, config
      assert_match new_webhook, config
    end
  end

  test "adds the webhook job" do
    provide_existing_initializer_file

    run_generator

    assert_directory "app/jobs"
    assert_file "app/jobs/product_update_job.rb" do |job|
      assert_match 'class ProductUpdateJob < ActiveJob::Base', job
    end
  end

  private

  def exisiting_webhook
    "{topic: 'carts/update', address: 'https://example.com/webhooks/carts_update', format: 'json'}"
  end

  def new_webhook
    "{topic: 'products/update', address: 'https://example.com/webhooks/product_update', format: 'json'}"
  end
end
