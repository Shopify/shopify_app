# frozen_string_literal: true

module ShopifyApp
  module OmniAuth
    class Configuration
      attr_reader :strategy, :request
      attr_writer :client_options_site, :scopes, :per_user_permissions

      def initialize(strategy, request)
        @strategy = strategy
        @request = request
      end

      def build_options
        strategy.options[:client_options][:site] = client_options_site
        strategy.options[:scope] = scopes
        strategy.options[:old_client_secret] = ShopifyApp.configuration.old_secret
        strategy.options[:per_user_permissions] = request_online_tokens?
      end

      private

      def request_online_tokens?
        return @per_user_permissions unless @per_user_permissions.nil?
        default_request_online_tokens?
      end

      def scopes
        @scopes || default_scopes
      end

      def client_options_site
        @client_options_site || default_client_options_site
      end

      def default_scopes
        if request_online_tokens?
          ShopifyApp.configuration.user_access_scopes
        else
          ShopifyApp.configuration.shop_access_scopes
        end
      end

      def default_client_options_site
        return '' unless shop_domain.present?
        "https://#{shopify_auth_params[:shop]}"
      end

      def default_request_online_tokens?
        strategy.session[:user_tokens] && !update_shop_scopes?
      end

      def update_shop_scopes?
        ShopifyApp.configuration.shop_access_scopes_strategy.scopes_mismatch?(shop_domain)
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
end
