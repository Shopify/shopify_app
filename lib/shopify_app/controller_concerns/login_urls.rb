# frozen_string_literal: true

module ShopifyApp
  module LoginUrls
    include ShopifyApp::SanitizedParams

    protected

    def login_url_with_optional_shop(top_level: false)
      if ShopifyApp.configuration.login_url =~ %r|\Ahttps?://|
        url = ShopifyApp.configuration.login_url
      else
        url = "https://#{ShopifyAPI::Context.host_name}#{ShopifyApp.configuration.login_url}"
      end

      query_params = login_url_params(top_level: top_level)

      url = "#{url}?#{query_params.to_query}" if query_params.present?
      url
    end

    def login_url_params(top_level:)
      query_params = {}
      query_params[:shop] = sanitized_params[:shop] if params[:shop].present?

      return_to = RedirectSafely.make_safe(session[:return_to] || params[:return_to], nil)

      if return_to.present? && return_to_param_required?
        query_params[:return_to] = return_to
      end

      has_referer_shop_name = referer_sanitized_shop_name.present?

      if has_referer_shop_name
        query_params[:shop] ||= referer_sanitized_shop_name
      end

      if params[:host].present?
        query_params[:host] ||= params[:host]
      end

      query_params[:top_level] = true if top_level
      query_params
    end

    def shop_login
      ShopifyApp::Utils.shop_login_url(shop: params[:shop], host: params[:host], return_to: request.fullpath)
    end
  end
end
