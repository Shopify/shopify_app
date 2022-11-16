# frozen_string_literal: true

module ShopifyApp
  module RequireKnownShop
    extend ActiveSupport::Concern

    included do
      ShopifyApp::Logger.deprecated("RequireKnownShop has been replaced by to EnsureInstalled."\
        " Please use EnsureInstalled controller concern for the same behavior", "22.0.0")
    end

    include ShopifyApp::EnsureInstalled
  end
end
