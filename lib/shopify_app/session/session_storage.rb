# frozen_string_literal: true

module ShopifyApp
  module SessionStorage
    extend ActiveSupport::Concern

    included do
      validates :shopify_token, presence: true
      validates :api_version, presence: true
      model_callback_methods_to_call_after_save = Rails::VERSION::MAJOR >= 6 ? [:after_save] : [:after_create, :after_update]

      model_callback_methods_to_call_after_save.each do |callback_name|
        send(callback_name, :save_session_to_repository)
      end
    end

    def with_shopify_session(&block)
      ShopifyApp::Auth::Session.temp(shop: shopify_domain, access_token: shopify_token) do |session|
        block.call(session)
      end
    end
  end
end
