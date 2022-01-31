# frozen_string_literal: true
module ShopifyApp
  module UserSessionStorageWithScopes
    extend ActiveSupport::Concern
    include ::ShopifyApp::SessionStorage

    included do
      validates :shopify_domain, presence: true
    end

    class_methods do
      def store(auth_session, user)
        user = find_or_initialize_by(shopify_user_id: user[:id])
        user.shopify_token = auth_session.access_token
        user.shopify_domain = auth_session.shop
        user.access_scopes = auth_session.scope.to_s

        user.save!
        user.id
      end

      def retrieve(id)
        user = find_by(id: id)
        construct_session(user)
      end

      def retrieve_by_shopify_user_id(user_id)
        user = find_by(shopify_user_id: user_id)
        construct_session(user)
      end

      private

      def construct_session(user)
        return unless user

        associated_user = ShopifyAPI::Auth::AssociatedUser.new(
          id: user.shopify_user_id,
          first_name: "",
          last_name: "",
          email: "",
          email_verified: false,
          account_owner: false,
          locale: "",
          collaborator: false
        )

        ShopifyAPI::Auth::Session.new(
          shop: user.shopify_domain,
          access_token: user.shopify_token,
          scope: user.access_scopes,
          associated_user_scope: user.access_scopes,
          associated_user: associated_user
        )
      end
    end

    def access_scopes=(scopes)
      super(scopes)
    rescue NotImplementedError, NoMethodError
      raise NotImplementedError, "#access_scopes= must be defined to handle storing access scopes: #{scopes}"
    end

    def access_scopes
      super
    rescue NotImplementedError, NoMethodError
      raise NotImplementedError, "#access_scopes= must be defined to hook into stored access scopes"
    end
  end
end
