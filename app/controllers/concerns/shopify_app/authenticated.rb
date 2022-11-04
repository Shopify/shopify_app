# frozen_string_literal: true

module ShopifyApp
  module Authenticated
    include ShopifyApp::EnsureHasSession

    included do
      ShopifyApp::Utils::Logger.deprecated("Authenticated has been renamed to EnsureHasSession")
    end
  end
end
