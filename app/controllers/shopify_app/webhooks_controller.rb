module ShopifyApp
  class WebhooksController < ActionController::Base
    include ShopifyApp::WebhookVerification

    class ShopifyApp::MissingWebhookJobError < StandardError; end

    def receive
      params.try(:permit!)
      job_args = {shop_domain: shop_domain, webhook: webhook_params.to_h}
      webhook_job_klass.perform_later(job_args)
      head :no_content
    end

    private

    def webhook_params
      params.except(:controller, :action, :type)
    end

    def webhook_job_klass
      "#{webhook_type.classify}Job".safe_constantize or raise ShopifyApp::MissingWebhookJobError
    end

    def webhook_type
      params[:type]
    end
  end
end
