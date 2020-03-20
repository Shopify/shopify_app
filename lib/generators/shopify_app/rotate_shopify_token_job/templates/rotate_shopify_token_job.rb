# typed: true
# frozen_string_literal: true

module Shopify
  class RotateShopifyTokenJob < ActiveJob::Base
    def perform(params)
      @shop = Shop.find_by(shopify_domain: params[:shop_domain])
      return unless @shop

      config = ShopifyApp.configuration
      uri = URI("https://#{@shop.shopify_domain}/admin/oauth/access_token")
      post_data = {
        client_id: config.api_key,
        client_secret: config.secret,
        refresh_token: params[:refresh_token],
        access_token: @shop.shopify_token,
      }

      @response = Net::HTTP.post_form(uri, post_data)
      return log_error(response_exception_error_message) unless @response.is_a?(Net::HTTPSuccess)

      access_token = JSON.parse(@response.body)['access_token']
      return log_error(no_access_token_error_message) unless access_token

      @shop.update(shopify_token: access_token)
    end

    private

    def log_error(message)
      Rails.logger.error(message)
    end

    def no_access_token_error_message
      "RotateShopifyTokenJob response returned no access token for shop: #{@shop.shopify_domain}"
    end

    def response_exception_error_message
      "RotateShopifyTokenJob failed for shop: #{@shop.shopify_domain}." \
        "Response returned status: #{@response.code}. Error message: #{@response.message}. "
    end
  end
end
