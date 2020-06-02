# frozen_string_literal: true
module ShopifyApp
  module CsrfProtection
    extend ActiveSupport::Concern

    MissingIncludeError = Class.new(StandardError)

    included do
      unless ancestors.include?(ShopifyApp::LoginProtection)
        raise(MissingIncludeError, 'You must include ShopifyApp::LoginProtection before including this module.')
      end

      protect_from_forgery with: :exception, unless: :valid_session_token?
    end

    private

    def valid_session_token?
      jwt_shopify_domain.present?
    end
  end
end
