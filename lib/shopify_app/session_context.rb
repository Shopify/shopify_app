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

      def host
        ShopifyApp.configuration.host || ENV["HOST"] || raise("Host not configured")
      end

      def host_scheme
        host.start_with?("https") ? "https" : "http"
      end

      def api_key
        ShopifyApp.configuration.api_key
      end

      def api_secret_key
        ShopifyApp.configuration.secret
      end

      def embedded?
        ShopifyApp.configuration.embedded_app
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
