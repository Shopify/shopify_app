# frozen_string_literal: true

module ShopifyApp
  class SessionRepository
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
        load_shop_storage || raise(
          ::ShopifyApp::ConfigurationError,
          "ShopifySessionRepository.shop_storage is not configured!",
        )
      end

      def user_storage
        load_user_storage
      end

      # ShopifyAPI::Auth::SessionStorage override
      def store_session(session)
        if session.online?
          user = session.associated_user
          ShopifyApp::Logger.debug("Storing online user session - session: #{session.id}")
          user_storage.store(session, user)
        else
          ShopifyApp::Logger.debug("Storing offline store session - session: #{session.id}")
          shop_storage.store(session)
        end
      end

      # ShopifyAPI::Auth::SessionStorage override
      def load_session(id)
        match = id.match(/^offline_(.*)/)
        if match
          domain = match[1]
          ShopifyApp::Logger.debug("Loading session by domain - domain: #{domain}")
          retrieve_shop_session_by_shopify_domain(domain)
        else
          user = id.split("_").last
          ShopifyApp::Logger.debug("Loading session by user_id - user: #{user}")
          retrieve_user_session_by_shopify_user_id(user)
        end
      end

      # ShopifyAPI::Auth::SessionStorage override
      def delete_session(id)
        match = id.match(/^offline_(.*)/)

        record = if match
          domain = match[1]
          ShopifyApp::Logger.debug("Destroying session by domain - domain: #{domain}")
          Shop.find_by(shopify_domain: match[1])
        else
          shopify_user_id = id.split("_").last
          ShopifyApp::Logger.debug("Destroying session by user - user_id: #{shopify_user_id}")
          User.find_by(shopify_user_id: shopify_user_id)
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
