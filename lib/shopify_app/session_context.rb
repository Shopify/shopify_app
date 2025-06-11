# frozen_string_literal: true

module ShopifyApp
  # Manages the current session context, replacing ShopifyAPI::Context
  module SessionContext
    class << self
      attr_reader :active_session

      def activate_session(session)
        @active_session = session
        @activation_time = Time.now
      end

      def deactivate_session
        @active_session = nil
        @activation_time = nil
      end

      def with_session(session)
        previous_session = @active_session
        activate_session(session)
        yield
      ensure
        @active_session = previous_session
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
  end
end
