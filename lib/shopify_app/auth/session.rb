# frozen_string_literal: true

require "securerandom"
require "time"

module ShopifyApp
  module Auth
    class Session
      attr_reader :id
      attr_accessor :state, :access_token, :shop, :scope, :associated_user_scope,
                    :expires, :associated_user, :shopify_session_id

      def online?
        @is_online
      end

      def expired?
        @expires ? @expires < Time.now : false
      end

      def initialize(shop:, id: nil, state: nil, access_token: "", scope: [], associated_user_scope: nil, expires: nil,
        is_online: nil, associated_user: nil, shopify_session_id: nil)
        @id = id || SecureRandom.uuid
        @shop = shop
        @state = state
        @access_token = access_token
        @scope = AuthScopes.new(scope)
        @associated_user_scope = associated_user_scope.nil? ? nil : AuthScopes.new(associated_user_scope)
        @expires = expires
        @associated_user = associated_user
        @is_online = is_online || !associated_user.nil?
        @shopify_session_id = shopify_session_id
      end

      class << self
        def temp(shop:, access_token:, &blk)
          original_session = SessionContext.active_session
          temp_session = Session.new(shop: shop, access_token: access_token)

          begin
            SessionContext.activate_session(temp_session)
            yield temp_session
          ensure
            SessionContext.activate_session(original_session)
          end
        end

        def from_access_token_response(shop:, access_token_response:)
          is_online = access_token_response["online_token"]

          if is_online
            associated_user = AssociatedUser.new(access_token_response["associated_user"])
            associated_user_scope = access_token_response["associated_user_scope"]
            id = "#{shop}_#{associated_user.id}"
          else
            id = "offline_#{shop}"
          end

          expires = if access_token_response["expires_in"]
            Time.now + access_token_response["expires_in"].to_i
          end

          new(
            id: id,
            shop: shop,
            access_token: access_token_response["access_token"],
            scope: access_token_response["scope"],
            is_online: is_online,
            associated_user_scope: associated_user_scope,
            associated_user: associated_user,
            expires: expires,
            shopify_session_id: access_token_response["session"],
          )
        end

        def from_jwt_payload(shop:, payload:, access_token: nil, is_online: false)
          user_id = payload["sub"]
          
          if is_online && user_id
            associated_user = AssociatedUser.new(
              "id" => user_id.to_i,
              "account_owner" => payload["account_owner"] || false
            )
            id = "#{shop}_#{user_id}"
          else
            id = "offline_#{shop}"
          end

          new(
            id: id,
            shop: shop,
            access_token: access_token,
            scope: payload["scope"] || [],
            is_online: is_online,
            associated_user: associated_user,
            expires: payload["exp"] ? Time.at(payload["exp"]) : nil,
            shopify_session_id: payload["sid"],
          )
        end

        def deserialize(str)
          JSON.parse(str, object_class: OpenStruct).tap do |session_data|
            session = new(
              shop: session_data.shop,
              id: session_data.id,
              state: session_data.state,
              access_token: session_data.access_token,
              scope: session_data.scope&.scopes || [],
              associated_user_scope: session_data.associated_user_scope&.scopes || [],
              expires: session_data.expires ? Time.parse(session_data.expires) : nil,
              is_online: session_data.online,
              shopify_session_id: session_data.shopify_session_id
            )

            if session_data.associated_user
              session.associated_user = AssociatedUser.new(session_data.associated_user.to_h)
            end

            return session
          end
        end
      end

      def copy_attributes_from(other)
        @id = other.id
        @shop = other.shop
        @state = other.state
        @access_token = other.access_token
        @scope = other.scope.dup
        @associated_user_scope = other.associated_user_scope&.dup
        @expires = other.expires
        @is_online = other.online?
        @associated_user = other.associated_user
        @shopify_session_id = other.shopify_session_id
        self
      end

      def serialize
        {
          id: @id,
          shop: @shop,
          state: @state,
          access_token: @access_token,
          scope: @scope,
          associated_user_scope: @associated_user_scope,
          expires: @expires&.iso8601,
          online: @is_online,
          associated_user: @associated_user,
          shopify_session_id: @shopify_session_id,
        }.to_json
      end

      def ==(other)
        return false unless other.is_a?(Session)

        id == other.id &&
          shop == other.shop &&
          state == other.state &&
          scope == other.scope &&
          associated_user_scope == other.associated_user_scope &&
          (!(expires.nil? ^ other.expires.nil?) && (expires.nil? || expires.to_i == other.expires.to_i)) &&
          online? == other.online? &&
          associated_user == other.associated_user &&
          shopify_session_id == other.shopify_session_id
      end

      alias_method :eql?, :==
    end
  end
end 