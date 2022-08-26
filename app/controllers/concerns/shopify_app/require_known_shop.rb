# frozen_string_literal: true

module ShopifyApp
  module RequireKnownShop
    extend ActiveSupport::Concern
    include ShopifyApp::RedirectForEmbedded

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
        if embedded_param?
          redirect_for_embedded
        else
          redirect_to(shop_login)
        end
      end
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
  end
end
