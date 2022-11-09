# frozen_string_literal: true

module ShopifyApp
  module Authenticated
    extend ShopifyApp::EnsureHasSession
    extend ActiveSupport::Concern

    included do
      ShopifyApp::Logger.deprecated("Authenticated has been renamed to EnsureHasSession")
    end
  end
end
