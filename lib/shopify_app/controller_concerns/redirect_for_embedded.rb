# frozen_string_literal: true

module ShopifyApp
  module RedirectForEmbedded
    include ShopifyApp::SanitizedParams

    private

    def embedded_redirect_url?
      ShopifyApp.configuration.embedded_redirect_url.present?
    end

    def embedded_param?
      embedded_redirect_url? && params[:embedded].present? && loaded_directly_from_admin?
    end

    def loaded_directly_from_admin?
      ShopifyApp.configuration.embedded_app? && params[:embedded] == "1"
    end

    def redirect_for_embedded
      # Don't actually redirect if we're already in the redirect route - we want the request to reach the FE
      unless request.path == ShopifyApp.configuration.embedded_redirect_url
        ShopifyApp::Logger.debug("Redirecting to #{redirect_uri_for_embedded}")
        redirect_to(redirect_uri_for_embedded)
      end
    end

    def redirect_uri_for_embedded
      redirect_query_params = {}
      redirect_uri = "#{ShopifyAPI::Context.host}#{ShopifyApp.configuration.login_url}"
      redirect_query_params[:shop] = sanitized_shop_name
      redirect_query_params[:shop] ||= referer_sanitized_shop_name if referer_sanitized_shop_name.present?
      redirect_query_params[:host] ||= params[:host] if params[:host].present?
      redirect_uri = "#{redirect_uri}?#{redirect_query_params.to_query}" if redirect_query_params.present?

      query_params = sanitized_params.except(:redirect_uri)
      query_params[:redirectUri] = redirect_uri

      "#{ShopifyApp.configuration.embedded_redirect_url}?#{query_params.to_query}"
    end
  end
end
