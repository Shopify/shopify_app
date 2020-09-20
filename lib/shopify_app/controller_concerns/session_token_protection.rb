# frozen_string_literal: true

module ShopifyApp
  module SessionTokenProtection
    extend ActiveSupport::Concern
    include ShopifyApp::AccessToken

    class ShopifyDomainNotFound < StandardError; end

    included do
    end

    def activate_shopify_session
      if user_session_expected? && user_session.blank?
        signal_access_token_required
        return head(:unauthorized)
      end

      return head(:unauthorized) if current_shopify_session.blank?

      begin
        ShopifyAPI::Base.activate_session(current_shopify_session)
        yield
      ensure
        ShopifyAPI::Base.clear_session
      end
    end

    def current_shopify_session
      @current_shopify_session ||=
        begin
          shopify_session || user_session || shop_session
        end
    end

    def current_shopify_domain
      return shopify_domain if shopify_domain.present?

      raise ShopifyDomainNotFound
    end

    private

    def shopify_session
      # TODO: Determine a true session using the `sid` field from a JWT payload
    end

    def user_session
      return unless shopify_user_id
      ShopifyApp::SessionRepository.retrieve_user_session_by_shopify_user_id(shopify_user_id)
    end

    def shop_session
      return unless shopify_domain
      ShopifyApp::SessionRepository.retrieve_shop_session_by_shopify_domain(shopify_domain)
    end

    def shopify_domain
      request.env['jwt.shopify_domain']
    end

    def shopify_user_id
      request.env['jwt.shopify_user_id']
    end
  end
end
