class WebhooksController < ApplicationController
  include ShopifyApp::WebhookVerification

  class ShopifyApp::MissingWebhookJobError < StandardError; end

  def receive
    job_args = {shop_domain: shop_domain, webhook: webhook_params}
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
