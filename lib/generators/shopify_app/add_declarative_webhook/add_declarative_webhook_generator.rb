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
        route = "\t\t\tpost '#{file_name}', to: '#{file_name}#receive'\n"
        inject_into_file("config/routes.rb", route, after: /namespace :webhooks do\n/)
      end

      private

      def file_name
        path.split("/").last
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
