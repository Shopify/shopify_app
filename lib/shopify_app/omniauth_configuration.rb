# frozen_string_literal: true

module ShopifyApp
  class OmniAuthConfiguration
    class << self
      def api_key
        ShopifyApp.configuration.api_key
      end

      def secret
        ShopifyApp.configuration.secret
      end

      def old_secret
        ShopifyApp.configuration.old_secret
      end
    end

    attr_reader :strategy
    attr_reader :request

    def initialize(strategy, request)
      @strategy = strategy
      @request = request
    end

    def scopes
      if request_online_tokens?
        ShopifyApp.configuration.user_access_scopes
      else
        ShopifyApp.configuration.shop_access_scopes
      end
    end

    def client_options_site
      return '' unless shop_domain.present?
      "https://#{shopify_auth_params[:shop]}"
    end

    def request_online_tokens?
      strategy.session[:user_tokens] && !update_shop_scopes?
    end

    private

    def update_shop_scopes?
      ShopifyApp::ShopAccessScopesStrategy.scopes_mismatch?(shop_domain)
    rescue NotImplementedError
      false
    end

    def shop_domain
      request.params['shop'] || (shopify_auth_params && shopify_auth_params['shop'])
    end

    def shopify_auth_params
      strategy.session['shopify.omniauth_params']&.with_indifferent_access
    end
  end
end
