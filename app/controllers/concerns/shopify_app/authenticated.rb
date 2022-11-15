# frozen_string_literal: true

module ShopifyApp
  module Authenticated
    extend ActiveSupport::Concern

    included do
      ShopifyApp::Logger.deprecated("RequireKnownShop has been replaced by to EnsureInstalled."\
        " Please use EnsureInstalled controller concern for the same behavior")
    end

    include ShopifyApp::EnsureHasSession
  end
end
