# frozen_string_literal: true
require 'test_helper'

class OrderUpdateJob < ActiveJob::Base
  def perform; end
end

module ShopifyApp
  class WebhooksControllerTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    setup do
      WebhooksController.any_instance.stubs(:verify_request).returns(true)
      WebhooksController.any_instance.stubs(:webhook_namespace).returns(nil)
    end

    test "receives webhook and performs job" do
      send_webhook 'order_update', { foo: :bar }
      assert_response :ok
      assert_enqueued_jobs 1
    end

    test "passes webhook to the job" do
      webhook = { 'foo' => 'bar' }
      job_args = { shop_domain: "test.myshopify.com", webhook: webhook }

      OrderUpdateJob.expects(:perform_later).with(job_args)

      send_webhook 'order_update', webhook
      assert_response :ok
    end

    test "returns error for webhook with no job class" do
      assert_raises ShopifyApp::MissingWebhookJobError do
        send_webhook 'test', { foo: :bar }
      end
    end

    private

    def send_webhook(name, data)
      post(shopify_app.webhooks_path(name), params: data,
           headers: { 'HTTP_X_SHOPIFY_SHOP_DOMAIN' => 'test.myshopify.com' })
    end
  end
end
