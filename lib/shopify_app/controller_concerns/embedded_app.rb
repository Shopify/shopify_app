# frozen_string_literal: true

module ShopifyApp
  module EmbeddedApp
    extend ActiveSupport::Concern

    include ShopifyApp::FrameAncestors

    included do
      layout :embedded_app_layout
      after_action :set_esdk_headers, if: -> { ShopifyApp.configuration.embedded_app? }
    end

    protected

    def use_embedded_app_layout?
      ShopifyApp.configuration.embedded_app?
    end

    private

    def embedded_app_layout
      "embedded_app" if use_embedded_app_layout?
    end

    def set_esdk_headers
      response.set_header("P3P", 'CP="Not used"')
      response.headers.except!("X-Frame-Options")
    end
  end
end
