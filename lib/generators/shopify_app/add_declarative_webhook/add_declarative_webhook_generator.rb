# frozen_string_literal: true

require "rails/generators/base"

module ShopifyApp
  module Generators
    class AddDeclarativeWebhookGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)
      class_option :topic, type: :string, aliases: "-t", required: true
      class_option :path, type: :string, aliases: "-p", required: true

      hook_for :test_framework, as: :job, in: :rails do |instance, generator|
        instance.invoke(generator, [instance.send(:file_name)])
      end

      def add_webhook_job
        namespace = ShopifyApp.configuration.webhook_jobs_namespace
        @job_file_name = if namespace.present?
          "#{namespace}/#{file_name}_job"
        else
          "#{file_name}_job"
        end
        @job_class_name = @job_file_name.classify
        template("webhook_job.rb", "app/jobs/#{@job_file_name}.rb")
      end

      def add_webhook_controller
        @controller_file_name = "#{file_name}_controller"
        @controller_class_name = @controller_file_name.classify
        template("webhook_controller.rb", "app/controllers/webhooks/#{@controller_file_name}.rb")
      end

      def add_webhook_route
        webhook_route = "post \"#{route_path}\", to: \"webhooks/#{file_name}#receive\""
        routes = File.read("config/routes.rb")
        return if routes.include?(webhook_route)

        mount_engine_route = /^\s*mount\s+ShopifyApp::Engine,\s+at:\s+["']\/["'].*\n/

        if routes.match?(mount_engine_route)
          inject_into_file("config/routes.rb", "  #{webhook_route}\n", before: mount_engine_route)
        else
          route(webhook_route)
        end
      end

      private

      def file_name
        path.split("/").last
      end

      def route_path
        "/#{path.delete_prefix("/")}"
      end

      def topic
        options["topic"]
      end

      def path
        options["path"]
      end
    end
  end
end
