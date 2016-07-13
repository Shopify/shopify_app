class AppProxyController < ApplicationController
  if Rails.env.development? || Rails.env.test?
   around_action :shopify_session
  else
   include ShopifyApp::AppProxyVerification
  end

  def index
    render layout: false, content_type: Rails.env.production? ? 'application/liquid' :  'text/html'
  end

end
