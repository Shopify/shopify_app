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

      original_path = request.path
      original_params = request.query_parameters.except(:host, :shop, :id_token)
      original_path += "?#{original_params.to_query}" if original_params.present?

      embedded_app_url = safe_embedded_app_url(host)
      redirect_path = embedded_app_url ? embedded_app_url + original_path.to_s : ShopifyApp.configuration.root_url
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

    def safe_embedded_app_url(host)
      decoded_host = Base64.decode64(host.to_s)
      return if deduced_phishing_attack?(decoded_host)

      ShopifyAPI::Auth.embedded_app_url(Base64.strict_encode64(decoded_host))
    end

    def deduced_phishing_attack?(decoded_host)
      sanitized_host = ShopifyApp::Utils.sanitize_shop_domain(decoded_host) unless unsafe_embedded_host?(decoded_host)
      if sanitized_host.nil?
        message = "Host param for redirect to embed app in admin is not from a trusted domain, " \
          "redirecting to root as this is likely a phishing attack."
        ShopifyApp::Logger.info(message)
      end
      sanitized_host.nil?
    end

    def unsafe_embedded_host?(decoded_host)
      return true if decoded_host.empty? || !decoded_host.valid_encoding?
      return true if unsafe_embedded_host_characters?(decoded_host)

      embedded_host_authority(decoded_host).include?("@")
    end

    def unsafe_embedded_host_characters?(decoded_host)
      decoded_host.each_char.any? do |character|
        character_code = character.ord
        character_code <= 0x20 || character_code == 0x7f || character == "\\"
      end
    end

    def embedded_host_authority(decoded_host)
      decoded_host.sub(%r{\Ahttps?://}i, "").split(%r{[/?#]}, 2).first.to_s
    end
  end
end
