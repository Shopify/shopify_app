# frozen_string_literal: true

module ShopifyApp
  module RequireKnownShop
    extend ActiveSupport::Concern

    included do
      before_action :check_shop_domain
      before_action :check_shop_known
    end

    def current_shopify_domain
      return if params[:shop].blank?
      @shopify_domain ||= ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end

    private

    def check_shop_domain
      redirect_to(ShopifyApp.configuration.login_url) unless current_shopify_domain
    end

    def check_shop_known
      @shop = SessionRepository.retrieve_shop_session_by_shopify_domain(current_shopify_domain)
      unless @shop
        if params[:embedded].present? && params[:embedded] == "1"
          redirect_to(redirect_uri_for_embedded)
          # redirect_for_embedded
        else
          redirect_to(shop_login)
        end
      end
      # redirect_to(shop_login) unless @shop
    end

    def shop_login
      url = URI(ShopifyApp.configuration.login_url)

      url.query = URI.encode_www_form(
        shop: params[:shop],
        host: params[:host],
        return_to: request.fullpath,
      )

      url.to_s
    end

    def redirect_uri_for_embedded
      redirect_query_params = {}
      redirect_uri = "https://#{ShopifyAPI::Context.host_name}#{ShopifyApp.configuration.login_url}"
      redirect_query_params[:shop] = sanitized_shop_name
      redirect_query_params[:shop] ||= referer_sanitized_shop_name if referer_sanitized_shop_name.present?
      redirect_query_params[:host] ||= host if params[:host].present?
      redirect_uri = "#{redirect_uri}?#{redirect_query_params.to_query}" if redirect_query_params.present?

      query_params = sanitized_params.except(:redirect_uri, :embedded)
      query_params[:redirect_uri] = redirect_uri

      "#{ShopifyApp.configuration.embedded_redirect_url}?#{query_params.to_query}"
    end
  end
end
