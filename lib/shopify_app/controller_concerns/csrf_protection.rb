# frozen_string_literal: true

module ShopifyApp
  module CsrfProtection
    extend ActiveSupport::Concern
    included do
      protect_from_forgery with: :exception, unless: :valid_session_token?
    end

    private

    def valid_session_token?
      request.env["jwt.shopify_domain"]
    end
  end
end
