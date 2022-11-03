# frozen_string_literal: true

module ShopifyApp
  module Authenticated
    include ShopifyApp::EnsureHasSession

    included do
      ShopifyApp::Utils.log_deprecations("RequireKnownShop has been renamed to EnsureInstalled")
    end
  end
end
