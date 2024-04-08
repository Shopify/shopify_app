# frozen_string_literal: true

module ShopifyApp
  module EnsureAuthenticatedLinks
    extend ActiveSupport::Concern

    included do
      before_action :redirect_to_splash_page, if: :missing_expected_jwt?
    end

    private

    def splash_page
      splash_page_with_params(
        return_to: request.fullpath,
        shop: current_shopify_domain,
        host: params[:host],
        embedded: params[:embedded],
      )
    end

    def splash_page_with_params(params)
      uri = URI(base_url)
      uri.query = params.compact.to_query
      uri.to_s
    end

    def base_url
      ShopifyApp.configuration.root_url.presence || root_path
    end

    def redirect_to_splash_page
      redirect_to(splash_page)
    rescue ::ShopifyApp::ShopifyDomainNotFound => error
      ShopifyApp::Logger.warn("Redirecting to login: [#{error.class}]"\
        " Could not determine current shop domain")
      redirect_to(ShopifyApp.configuration.login_url)
    end

    def missing_expected_jwt?
      false
    end
  end
end
