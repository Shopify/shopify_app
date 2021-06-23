# frozen_string_literal: true

module ShopifyApp
  module EnsureAuthenticatedLinks
    extend ActiveSupport::Concern

    included do
      before_action :redirect_to_splash_page, if: :missing_expected_jwt?
    end

    private

    def redirect_to_splash_page
      splash_page_path = URI(ShopifyApp.configuration.root_url)
      splash_page_path.query = URI.encode_www_form(return_to: request.fullpath, shop: current_shopify_domain)
      redirect_to(splash_page_path.to_s)
    rescue ShopifyApp::LoginProtection::ShopifyDomainNotFound => error
      Rails.logger.warn("[ShopifyApp::EnsureAuthenticatedLinks] Redirecting to login: [#{error.class}] "\
                         "Could not determine current shop domain")
      redirect_to(ShopifyApp.configuration.login_url)
    end

    def missing_expected_jwt?
      jwt_shopify_domain.blank?
    end
  end
end
