require 'rails/generators/base'

module ShopifyApp
  module Generators
    class AddFulfillmentServiceGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      class_option :name, type: :string, aliases: "-n", required: true
      class_option :inventory_management, type: :boolean, required: false, default: true
      class_option :tracking_support, type: :boolean, required: false, default: true
      class_option :requires_shipping_method, type: :boolean, required: false, default: true

      def init_fulfillment_service_config
        initializer = load_initializer
        return if initializer.include?("config.fulfillment_services")

        inject_into_file(
          'config/initializers/shopify_app.rb',
          "  config.fulfillment_services = [\n  ]\n",
          before: 'end'
        )
      end

      def inject_fulfillment_service_to_shopify_app_initializer
        inject_into_file(
          'config/initializers/shopify_app.rb',
          fulfillment_service_config,
          after: "config.fulfillment_services = ["
        )

        initializer = load_initializer

        unless initializer.include?(fulfillment_service_config)
          shell.say "Error adding fulfillment_service to config. Add this line manually: #{fulfillment_service_config}", :red
        end
      end

      def add_fulfillment_service_job
        @service_file_name = name.underscore + '_fulfillment_service'
        @service_class_name  = @service_file_name.classify
        template 'fulfillment_service.rb', "app/lib/#{@service_file_name}.rb"
      end

      private

      def load_initializer
        File.read(File.join(destination_root, 'config/initializers/shopify_app.rb'))
      end

      def fulfillment_service_config
        "\n    {name: '#{name}', inventory_management: #{inventory_management}, tracking_support: #{tracking_support}, requires_shipping_method: #{requires_shipping_method}},"
      end

      def name
        options['name']
      end

      def inventory_management
        options['inventory_management']
      end

      def tracking_support
        options['tracking_support']
      end

      def requires_shipping_method
        options['requires_shipping_method']
      end
    end
  end
end
