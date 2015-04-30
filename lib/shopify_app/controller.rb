require 'shopify_app/login_protection'

module ShopifyApp
  module Controller
    extend ActiveSupport::Concern

    include ShopifyApp::LoginProtection

    def fullpage_redirect_to(url)
      if ShopifyApp.configuration.embedded_app?
        render inline: %Q(<script type="text/javascript">window.top.location.href = #{url.to_json};</script>)
      else
        redirect_to url
      end
    end

  end
end
