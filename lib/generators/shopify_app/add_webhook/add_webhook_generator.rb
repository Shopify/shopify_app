# frozen_string_literal: true

require "rails/generators/base"

module ShopifyApp
  module Generators
    class AddWebhookGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)
      class_option :topic, type: :string, aliases: "-t", required: true
      class_option :address, type: :string, aliases: "-a", required: true

      hook_for :test_framework, as: :job, in: :rails do |instance, generator|
        instance.invoke(generator, [instance.send(:job_file_name)])
      end

      def init_webhook_config
        initializer = load_initializer
        return if initializer.include?("config.webhooks")

        inject_into_file(
          "config/initializers/shopify_app.rb",
          "  config.webhooks = [\n  ]\n",
          after: /ShopifyApp\.configure.*\n/
        )
      end

      def inject_webhook_to_shopify_app_initializer
        inject_into_file(
          "config/initializers/shopify_app.rb",
          webhook_config,
          after: "config.webhooks = ["
        )

        initializer = load_initializer

        unless initializer.include?(webhook_config)
          shell.say("Error adding webhook to config. Add this line manually: #{webhook_config}", :red)
        end
      end

      def add_webhook_job
        @job_file_name = job_file_name + "_job"
        @job_class_name = @job_file_name.classify
        template("webhook_job.rb", "app/jobs/#{@job_file_name}.rb")
      end

      private

      def job_file_name
        address.split("/").last
      end

      def load_initializer
        File.read(File.join(destination_root, "config/initializers/shopify_app.rb"))
      end

      def webhook_config
        "\n    { topic: '#{topic}', address: '#{address}' },"
      end

      def topic
        options["topic"]
      end

      def address
        options["address"]
      end
    end
  end
end
