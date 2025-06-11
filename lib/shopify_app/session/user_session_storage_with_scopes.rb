# frozen_string_literal: true

module ShopifyApp
  module UserSessionStorageWithScopes
    extend ActiveSupport::Concern
    include ::ShopifyApp::SessionStorage

    included do
      validates :shopify_user_id, presence: true, uniqueness: true
    end

    module ClassMethods
      def store(auth_session, user)
        user_to_store = find_or_initialize_by(shopify_user_id: user.id)
        user_to_store.shopify_token = auth_session.access_token
        user_to_store.shopify_domain = auth_session.shop
        user_to_store.access_scopes = auth_session.scope.to_s if auth_session.scope
        user_to_store.expires_at = auth_session.expires if auth_session.expires
        user_to_store.save!
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

        ShopifyApp::Auth::Session.new(
          shop: user.shopify_domain,
          access_token: user.shopify_token,
          scope: user.access_scopes,
          expires: user.expires_at,
          associated_user: {
            "id" => user.shopify_user_id,
            "first_name" => user.first_name,
            "last_name" => user.last_name,
            "email" => user.email,
            "email_verified" => user.email_verified,
            "account_owner" => user.account_owner,
            "locale" => user.locale,
            "collaborator" => user.collaborator,
          },
        )
      end
    end

    def save_session_to_repository
      if ShopifyApp.configuration.user_session_repository.blank? || ShopifyApp::SessionRepository.user_storage.blank?
        return
      end

      ShopifyApp::SessionRepository.store_user_session(session, associated_user)
    end

    def access_scopes=(scopes)
      super(scopes)
      save_session_to_repository
    rescue ActiveRecord::RecordNotUnique
      logger.debug("Could not save session due to concurrent session update")
    end

    def update_access_scopes!(scopes)
      self.access_scopes = scopes
      save!
    end

    def expires_at
      return unless has_attribute?(:expires_at)

      super
    end

    def expires_at=(expires_at)
      return unless has_attribute?(:expires_at)

      super(expires_at)
    end

    def session_expired?
      expires_at.present? && expires_at < Time.now
    end
  end
end
