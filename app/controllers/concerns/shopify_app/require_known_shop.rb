# frozen_string_literal: true

module ShopifyApp
  module RequireKnownShop
    include ShopifyApp::EnsureInstalled

    included do
      ShopifyApp::Utils::Logger.deprecated("RequireKnownShop has been renamed to EnsureInstalled")
    end
  end
end
