# frozen_string_literal: true

module ShopifyApp
  module SessionUtils
    class << self
      # Generate a session ID from a Shopify ID token
      # @param id_token [String] The JWT ID token
      # @param online [Boolean] Whether this is for an online or offline session
      # @return [String] The generated session ID
      def session_id_from_shopify_id_token(id_token:, online:)
        return nil if id_token.blank?

        begin
          payload = ::ShopifyApp::Utils.validate_jwt_token(
            id_token,
            ShopifyApp.configuration.secret,
            clock_tolerance: 10,
          )

          return nil unless payload

          session_id_from_jwt_payload(payload: payload, online: online)
        rescue StandardError => e
          ShopifyApp::Logger.info("Failed to generate session ID from token: #{e.message}")
          nil
        end
      end

      # Generate a session ID from a JWT payload object
      # @param payload [Hash] The decoded JWT payload
      # @param online [Boolean] Whether this is for an online or offline session
      # @return [String] The generated session ID
      def session_id_from_jwt_payload(payload:, online:)
        return nil unless payload

        shop = payload["dest"]&.gsub(%r{^https://}, "")
        return nil if shop.blank?

        if online && payload["sub"]
          # Online session format: shop_user-id
          "#{shop}_#{payload["sub"]}"
        else
          # Offline session format: offline_shop
          "offline_#{shop}"
        end
      end

      # Get the current session ID based on various inputs
      def current_session_id(id_token, cookies, is_online)
        # First try to get from ID token
        if id_token.present?
          session_id_from_shopify_id_token(id_token: id_token, online: is_online)
        elsif cookies.present?
          # Fall back to cookie-based session
          extract_session_id_from_cookie(cookies)
        end
      end

      private

      def extract_session_id_from_cookie(cookies)
        # This would need to be implemented based on your cookie structure
        # For now, returning nil as a placeholder
        nil
      end
    end
  end
end
