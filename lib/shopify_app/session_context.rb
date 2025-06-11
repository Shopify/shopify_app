# frozen_string_literal: true

module ShopifyApp
  # Manages the current session context, replacing ShopifyAPI::Context
  class SessionContext
    thread_mattr_accessor :active_session

    class << self
      attr_reader :active_session

      def activate_session(session)
        self.active_session = session
      end

      def deactivate_session
        self.active_session = nil
      end

      def with_session(session)
        original_session = active_session
        activate_session(session)
        yield
      ensure
        activate_session(original_session)
      end

      def clear
        deactivate_session
      end

      # Use shopify_app_ai utilities for shop validation
      def validate_shop(shop)
        ::ShopifyApp::Utils.validate_shop_format(shop)
      end

      # Simplified host method using shopify_app_ai utilities
      def host
        ShopifyApp.configuration.host || ENV["HOST"] || raise("Host not configured")
      end

      def host_scheme
        host.start_with?("https") ? "https" : "http"
      end

      # Use shopify_app_ai patterns for configuration access
      def api_key
        ShopifyApp.configuration.api_key
      end

      def api_secret_key
        ShopifyApp.configuration.secret
      end

      def embedded?
        ShopifyApp.configuration.embedded_app
      end

      def scope
        ShopifyApp::Auth::AuthScopes.new(ShopifyApp.configuration.scope)
      end

      def private?
        !ENV.fetch("SHOPIFY_APP_PRIVATE_SHOP", "").empty?
      end

      def load_private_session
        return nil unless private?

        # For private apps, we create a simple session with the private shop
        private_shop = ENV.fetch("SHOPIFY_APP_PRIVATE_SHOP", nil)
        return nil unless private_shop

        ShopifyApp::Auth::Session.new(
          shop: private_shop,
          scope: ShopifyApp.configuration.scope,
        )
      end
    end

    attr_reader :shop_session, :user_session

    def initialize(shop_session: nil, user_session: nil)
      @shop_session = shop_session
      @user_session = user_session
    end

    def admin_session
      user_session || shop_session
    end

    def online_session
      user_session
    end

    def offline_session
      shop_session
    end

    def has_online_session?
      !user_session.nil?
    end

    def has_offline_session?
      !shop_session.nil?
    end
  end
end
