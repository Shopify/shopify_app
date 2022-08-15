# frozen_string_literal: true

module ShopifyApp
  class SessionRepository
    extend ShopifyAPI::Auth::SessionStorage

    class ConfigurationError < StandardError; end

    class << self
      attr_writer :shop_storage

      attr_writer :user_storage

      def retrieve_shop_session(id)
        shop_storage.retrieve(id)
      end

      def retrieve_user_session(id)
        user_storage.retrieve(id)
      end

      def retrieve_shop_session_by_shopify_domain(shopify_domain)
        shop_storage.retrieve_by_shopify_domain(shopify_domain)
      end

      def retrieve_user_session_by_shopify_user_id(user_id)
        user_storage.retrieve_by_shopify_user_id(user_id)
      end

      def store_shop_session(session)
        shop_storage.store(session)
      end

      def store_user_session(session, user)
        user_storage.store(session, user)
      end

      def shop_storage
        load_shop_storage || raise(ConfigurationError, "ShopifySessionRepository.shop_storage is not configured!")
      end

      def user_storage
        load_user_storage
      end

      # ShopifyAPI::Auth::SessionStorage override
      def store_session(session)
        if session.online?
          user_storage.store(session, session.associated_user)
        else
          shop_storage.store(session)
        end
      end

      # ShopifyAPI::Auth::SessionStorage override
      def load_session(id)
        match = id.match(/^offline_(.*)/)
        if match
          retrieve_shop_session_by_shopify_domain(match[1])
        else
          retrieve_user_session_by_shopify_user_id(id.split("_").last)
        end
      end

      # ShopifyAPI::Auth::SessionStorage override
      def delete_session(id)
        match = id.match(/^offline_(.*)/)

        record = if match
          Shop.find_by(shopify_domain: match[1])
        else
          User.find_by(shopify_user_id: id.split("_").last)
        end

        record.destroy

        true
      end

      private

      def load_shop_storage
        return unless @shop_storage

        @shop_storage.respond_to?(:safe_constantize) ? @shop_storage.safe_constantize : @shop_storage
      end

      def load_user_storage
        return NullUserSessionStore unless @user_storage

        @user_storage.respond_to?(:safe_constantize) ? @user_storage.safe_constantize : @user_storage
      end
    end
  end
end
