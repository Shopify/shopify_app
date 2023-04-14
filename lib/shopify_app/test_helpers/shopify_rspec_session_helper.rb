# frozen_string_literal: true

module ShopifyApp
  module TestHelpers
    module ShopifyRSpecSessionHelper
      def setup_shopify_session(session_id:, shop_domain:)
        ShopifyAPI::Auth::Session.new(id: session_id, shop: shop_domain).tap do |session|
          allow(ShopifyApp::SessionRepository).to receive(:load_session) { session }
          allow(ShopifyAPI::Utils::SessionUtils).to receive(:current_session_id) { session.id }
          ShopifyAPI::Context.activate_session(session)
        end
      end
    end
  end
end
