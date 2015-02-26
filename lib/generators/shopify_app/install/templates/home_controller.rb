class HomeController < ApplicationController
  around_filter :shopify_session
  layout 'embedded_app'

  def index
  end

end
