# frozen_string_literal: true

module ShopifyApp
  module UserSessionStorage
    extend ActiveSupport::Concern
    include ::ShopifyApp::SessionStorage

    included do
      validates :shopify_user_id, presence: true, uniqueness: true
    end

    module ClassMethods
      def store(auth_session, user)
        user = find_or_initialize_by(shopify_user_id: user.id)
        user.shopify_token = auth_session.access_token
        user.shopify_domain = auth_session.shop
        user.save!
      end

      def retrieve(id)
        user = find_by(id: id)
        construct_session(user)
      end

      def retrieve_by_shopify_user_id(user_id)
        user = find_by(shopify_user_id: user_id)
        construct_session(user)
      end

      def destroy_by_shopify_user_id(user_id)
        destroy_by(shopify_user_id: user_id)
      end

      private

      def construct_session(user)
        return unless user

        associated_user = {
          "id" => user.shopify_user_id,
          "first_name" => user.first_name,
          "last_name" => user.last_name,
          "email" => user.email,
          "email_verified" => user.email_verified,
        }

        ShopifyApp::Auth::Session.new(
          shop: user.shopify_domain,
          access_token: user.shopify_token,
          scope: user.scope,
          associated_user: associated_user,
        )
      end
    end

    def save_session_to_repository
      if ShopifyApp.configuration.user_session_repository.blank? || ShopifyApp::SessionRepository.user_storage.blank?
        return
      end

      ShopifyApp::SessionRepository.store_user_session(session, associated_user)
    end
  end
end
