class HomeController < ApplicationController
  around_filter :shopify_session

  def index
  end

end
