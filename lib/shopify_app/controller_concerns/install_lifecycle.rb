# frozen_string_literal: true

module ShopifyApp
  # Concerns that are used in the install lifecycle
  module InstallLifecycle
    private

    def install_webhooks
      return unless ShopifyApp.configuration.has_webhooks?

      WebhooksManager.queue(
        shop_name,
        token,
        ShopifyApp.configuration.webhooks
      )
    end

    def install_scripttags
      return unless ShopifyApp.configuration.has_scripttags?

      ScripttagsManager.queue(
        shop_name,
        token,
        ShopifyApp.configuration.scripttags
      )
    end

    def perform_after_authenticate_job
      config = ShopifyApp.configuration.after_authenticate_job

      return unless config && config[:job].present?

      if config[:inline] == true
        config[:job].perform_now(shop_domain: session[:shopify_domain])
      else
        config[:job].perform_later(shop_domain: session[:shopify_domain])
      end
    end
  end
end
