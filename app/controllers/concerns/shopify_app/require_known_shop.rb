# frozen_string_literal: true

module ShopifyApp
  module RequireKnownShop
    extend ActiveSupport::Concern

    included do
      ShopifyApp::Logger.deprecated("RequireKnownShop has been renamed to EnsureInstalled. Please use EnsureInstalled controller concern for the same behavior")
    end
    
    include ShopifyApp::EnsureInstalled
  end
end
