# frozen_string_literal: true

module ShopifyApp
  module RedirectForEmbedded
    include ShopifyApp::SanitizedParams
    include ShopifyApp::LoginUrls

    private

    def redirect_for_embedded
      if embedded_redirect_url?
        url = ShopifyApp.configuration.embedded_redirect_url

        query_params = sanitized_params.except(:redirect_uri, :embedded)
        query_params[:redirectUri] = login_url_with_optional_shop

        url = "#{url}?#{query_params.to_query}"
        redirect_to(url)
      else
        fullpage_redirect_to(login_url_with_optional_shop)
      end
    end

    def embedded_redirect_url?
      ShopifyApp.configuration.embedded_redirect_url.present?
    end

    def embedded_param?
      params[:embedded].present? && params[:embedded] == "1"
    end
  end
end
