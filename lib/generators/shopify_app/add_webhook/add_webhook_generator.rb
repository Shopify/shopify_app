require 'rails/generators/base'

module ShopifyApp
  module Generators
    class AddWebhookGenerator < Rails::Generators::Base
    class InvalidTopic < StandardError; end

      VALID_WEBHOOK_TOPICS = ['app/uninstalled',
                              'carts/create',
                              'carts/update',
                              'checkouts/create',
                              'checkouts/delete',
                              'checkouts/update',
                              'collections/create',
                              'collections/delete',
                              'collections/update',
                              'customer_groups/create',
                              'customer_groups/delete',
                              'customer_groups/update',
                              'customers/create',
                              'customers/delete',
                              'customers/disable',
                              'customers/enable',
                              'customers/update',
                              'disputes/create',
                              'disputes/update',
                              'fulfillment_events/create',
                              'fulfillment_events/delete',
                              'fulfillments/create',
                              'fulfillments/update',
                              'order_transactions/create',
                              'orders/cancelled',
                              'orders/create',
                              'orders/delete',
                              'orders/fulfilled',
                              'orders/paid',
                              'orders/partially_fulfilled',
                              'orders/updated',
                              'products/create',
                              'products/delete',
                              'products/update',
                              'refunds/create',
                              'shop/update',
                              'themes/publish'
                            ]

      source_root File.expand_path('../templates', __FILE__)

      class_option :topic, type: :string, aliases: "-t", required: true
      class_option :address, type: :string, aliases: "-a", required: true

      def init_webhook_config
        is_valid_topic?(topic)
        initializer = load_initializer
        return if initializer.include?("config.webhooks")

        inject_into_file(
          'config/initializers/shopify_app.rb',
          "  config.webhooks = [\n  ]\n",
          before: 'end'
        )
      end

      def inject_webhook_to_shopify_app_initializer
        inject_into_file(
          'config/initializers/shopify_app.rb',
          webhook_config,
          after: "config.webhooks = ["
        )

        initializer = load_initializer

        unless initializer.include?(webhook_config)
          shell.say "Error adding webhook to config. Add this line manually: #{webhook_config}", :red
        end
      end

      def add_webhook_job
        @job_file_name = address.split('/').last + '_job'
        @job_class_name  = @job_file_name.classify
        template 'webhook_job.rb', "app/jobs/#{@job_file_name}.rb"
      end

      private

      def is_valid_topic?(topic)
        unless VALID_WEBHOOK_TOPICS.any? { |valid| valid == topic }
          shell.say "A valid topic wasn't entered. Valid topics include: #{VALID_WEBHOOK_TOPICS}"
          raise InvalidTopic
        end
      end

      def load_initializer
        File.read(File.join(destination_root, 'config/initializers/shopify_app.rb'))
      end

      def webhook_config
        "\n    {topic: '#{topic}', address: '#{address}', format: 'json'},"
      end

      def topic
        options['topic']
      end

      def address
        options['address']
      end
    end
  end
end
