# frozen_string_literal: true

module ShopifyApp
  module TestHelpers
    module ShopifySessionHelper
      def setup_shopify_session(session_id:, shop_domain:)
        ShopifyApp::Auth::Session.new(id: session_id, shop: shop_domain).tap do |session|
          ShopifyApp::SessionRepository.stubs(:load_session).returns(session)
          ShopifyApp::SessionUtils.stubs(:current_session_id).returns(session.id)
          ShopifyApp::SessionUtils.stubs(:session_id_from_shopify_id_token).returns(session.id)
          ShopifyApp::SessionContext.activate_session(session)
        end
      end
    end
  end
end
