# frozen_string_literal: true
module ShopifyApp
  module ActualSessionStorage
    extend ActiveSupport::Concern
    include ::ShopifyApp::SessionStorage

    class_methods do
      def store(auth_session, session_id, user, expires_at)
        session = find_or_initialize_by(shopify_session_id: session_id)
        session.shopify_token = auth_session.token
        session.shopify_domain = auth_session.domain
        session.shopify_user_id = user[:id]
        session.shopify_token_expires_at = Time.at(expires_at)
        session.save!
        session.id
      end

      def retrieve(id)
        session = find_by(id: id)
        construct_session(session)
      end

      def retrieve_by_shopify_session_id(session_id)
        session = find_by(shopify_session_id: session_id)
        construct_session(session)
      end

      def clean_up
        where('shopify_token_expires_at < ?', Time.now).each(&:delete)
      end

      private

      def construct_session(session)
        return unless session
        ShopifyAPI::Session.new(
          domain: session.shopify_domain,
          token: session.shopify_token,
          api_version: session.api_version,
        )
      end
    end
  end
end
