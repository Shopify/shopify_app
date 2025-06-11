# frozen_string_literal: true

module ShopifyApp
  module RedirectForEmbedded
    include ShopifyApp::SanitizedParams

    def self.add_app_bridge_redirect_url_header(url, response)
      response.set_header("X-Shopify-API-Request-Failure-Reauthorize", "1")
      response.set_header("X-Shopify-API-Request-Failure-Reauthorize-Url", url)
    end

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
      redirect_uri = "#{ShopifyApp::SessionContext.host}#{ShopifyApp.configuration.login_url}"
      redirect_query_params[:shop] = sanitized_shop_name
      redirect_query_params[:shop] ||= referer_sanitized_shop_name if referer_sanitized_shop_name.present?
      redirect_query_params[:host] ||= params[:host] if params[:host].present?
      redirect_uri = "#{redirect_uri}?#{redirect_query_params.to_query}" if redirect_query_params.present?

      query_params = sanitized_params.except(:redirect_uri)
      query_params[:redirectUri] = redirect_uri

      "#{ShopifyApp.configuration.embedded_redirect_url}?#{query_params.to_query}"
    end

    def build_redirect_url(shop: current_shopify_domain, embedded:, host: params[:host])
      params = {
        shop: shop,
        host: host,
      }
      if embedded
        params[:embedded] = embedded
      end

      redirect_uri = "#{ShopifyApp::SessionContext.host}#{ShopifyApp.configuration.login_url}"
      redirect_uri = ShopifyApp::Utils.append_query(redirect_uri, params)

      redirect_uri
    end
  end
end
