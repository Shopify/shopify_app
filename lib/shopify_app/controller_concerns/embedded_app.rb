# frozen_string_literal: true

module ShopifyApp
  module EmbeddedApp
    extend ActiveSupport::Concern

    include ShopifyApp::FrameAncestors
    include ShopifyApp::SanitizedParams

    included do
      layout :embedded_app_layout
      after_action :set_esdk_headers, if: -> { ShopifyApp.configuration.embedded_app? }
    end

    protected

    def redirect_to_embed_app_in_admin
      ShopifyApp::Logger.debug("Redirecting to embed app in admin")

      host = if params[:host]
        params[:host]
      elsif params[:shop]
        Base64.encode64("#{sanitized_shop_name}/admin")
      else
        return redirect_to(ShopifyApp.configuration.login_url)
      end

      redirect_path = ShopifyAPI::Auth.embedded_app_url(host)
      redirect_path = ShopifyApp.configuration.root_url if deduced_phishing_attack?(redirect_path)
      redirect_to(redirect_path, allow_other_host: true)
    end

    def use_embedded_app_layout?
      ShopifyApp.configuration.embedded_app?
    end

    private

    def embedded_app_layout
      "embedded_app" if use_embedded_app_layout?
    end

    def set_esdk_headers
      response.set_header("P3P", 'CP="Not used"')
      response.headers.except!("X-Frame-Options")
    end

    def deduced_phishing_attack?(decoded_host)
      sanitized_host = ShopifyApp::Utils.sanitize_shop_domain(decoded_host)
      if sanitized_host.nil?
        message = "Host param for redirect to embed app in admin is not from a trusted domain, " \
          "redirecting to root as this is likely a phishing attack."
        ShopifyApp::Logger.info(message)
      end
      sanitized_host.nil?
    end
  end
end
