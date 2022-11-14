# frozen_string_literal: true

module ShopifyApp
  module Authenticated
    extend ActiveSupport::Concern

    included do
      ShopifyApp::Logger.deprecated("Authenticated has been renamed to EnsureHasSession")
    end

    include ShopifyApp::EnsureHasSession
  end
end
