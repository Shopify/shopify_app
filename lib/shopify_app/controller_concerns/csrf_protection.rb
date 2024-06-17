# frozen_string_literal: true

module ShopifyApp
  module CsrfProtection
    extend ActiveSupport::Concern
    included do
      include ShopifyApp::WithShopifyIdToken
      protect_from_forgery with: :exception, unless: :valid_session_token?
    end

    private

    def valid_session_token?
      jwt_payload.present?
    end
  end
end
