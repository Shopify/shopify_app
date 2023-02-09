# frozen_string_literal: true

module ShopifyApp
  module TestHelpers
    module ShopifySessionHelper
      def setup_shopify_session(session_id:, shop_domain:)
        ShopifyAPI::Auth::Session.new(id: session_id, shop: shop_domain).tap do |session|
          ShopifyApp::SessionRepository.stubs(:load_session).returns(session)
          ShopifyAPI::Utils::SessionUtils.stubs(:current_session_id).returns(session.id)
          ShopifyAPI::Context.activate_session(session)
        end
      end
    end
  end
end
