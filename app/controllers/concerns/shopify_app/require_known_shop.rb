# frozen_string_literal: true

module ShopifyApp
  module RequireKnownShop
    extend ActiveSupport::Concern
    include ShopifyApp::EnsureInstalled

    def self.extended(mod)
      ShopifyApp::Logger.deprecated("RequireKnownShop has been replaced by to EnsureInstalled."\
        " Please use EnsureInstalled controller concern for the same behavior", "22.0.0")
    end

    def self.included(mod)
      ShopifyApp::Logger.deprecated("RequireKnownShop has been replaced by to EnsureInstalled."\
        " Please use EnsureInstalled controller concern for the same behavior", "22.0.0")
    end
  end
end
