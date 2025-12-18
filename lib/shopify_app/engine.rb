# frozen_string_literal: true

module ShopifyApp
  module RedactJobParams
    private

    def args_info(job)
      log_disabled_classes = ["ShopifyApp::WebhooksManagerJob", "ShopifyApp::ScriptTagsManagerJob"]
      return "" if log_disabled_classes.include?(job.class.name)

      super
    end
  end

  class Engine < Rails::Engine
    engine_name "shopify_app"
    isolate_namespace ShopifyApp

    initializer "shopify_app.assets.precompile" do |app|
      app.config.assets.precompile += [
        "shopify_app/redirect.js",
      ]
    end

    initializer "shopify_app.redact_job_params" do |app|
      app.config.after_initialize do
        if ActiveJob::Base.respond_to?(:log_arguments?)
          WebhooksManagerJob.log_arguments = false
          ScriptTagsManagerJob.log_arguments = false
        elsif ActiveJob::Logging::LogSubscriber.private_method_defined?(:args_info)
          ActiveJob::Logging::LogSubscriber.prepend(RedactJobParams)
        end
      end
    end
  end
end
