module ShopifyApp
  module EmbeddedApp
    extend ActiveSupport::Concern

    included do
      if ShopifyApp.configuration.embedded_app?
        after_action :set_esdk_headers
        layout 'embedded_app'
      end
    end

    private

    def set_esdk_headers
      response.set_header('P3P', 'CP="Not used"')
      response.default_headers.delete('X-Frame-Options')
    end
  end
end
