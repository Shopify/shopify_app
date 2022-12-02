# frozen_string_literal: true

module ShopifyApp
  module RequireKnownShop
    extend ActiveSupport::Concern
    include ShopifyApp::EnsureInstalled

    included do
      ShopifyApp::Logger.deprecated("RequireKnownShop has been replaced by EnsureInstalled."\
        " Please use the EnsureInstalled controller concern for the same behavior", "22.0.0")
    end
  end
end
