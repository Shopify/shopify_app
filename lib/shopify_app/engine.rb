# frozen_string_literal: true
module ShopifyApp
  module RedactJobParams
    private

    def args_info(job)
      log_disabled_classes = %w(ShopifyApp::ScripttagsManagerJob ShopifyApp::WebhooksManagerJob)
      return "" if log_disabled_classes.include?(job.class.name)
      super
    end
  end

  class Engine < Rails::Engine
    engine_name 'shopify_app'
    isolate_namespace ShopifyApp

    initializer "shopify_app.assets.precompile" do |app|
      app.config.assets.precompile += %w[
        shopify_app/redirect.js
        shopify_app/post_redirect.js
        shopify_app/top_level.js
        shopify_app/enable_cookies.js
        shopify_app/request_storage_access.js
        storage_access.svg
      ]
    end

    initializer "shopify_app.middleware" do |app|
      app.config.middleware.insert_after(::Rack::Runtime, ShopifyApp::SameSiteCookieMiddleware)
      app.config.middleware.insert_after(ShopifyApp::SameSiteCookieMiddleware, ShopifyApp::AppBridgeMiddleware)

      if ShopifyApp.configuration.allow_jwt_authentication
        app.config.middleware.insert_after(ShopifyApp::AppBridgeMiddleware, ShopifyApp::JWTMiddleware)
      end
    end

    initializer "shopify_app.redact_job_params" do
      ActiveSupport.on_load(:active_job) do
        if ActiveJob::Base.respond_to?(:log_arguments?)
          WebhooksManagerJob.log_arguments = false
          ScripttagsManagerJob.log_arguments = false
        elsif ActiveJob::Logging::LogSubscriber.private_method_defined?(:args_info)
          ActiveJob::Logging::LogSubscriber.prepend(RedactJobParams)
        end
      end
    end
  end
end
