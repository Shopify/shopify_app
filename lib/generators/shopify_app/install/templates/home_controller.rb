class HomeController < ApplicationController
  around_filter :shopify_session
<% if -%>
  layout 'embedded_app'
<% end -%>

  def index
    @products = ShopifyAPI::Product.find(:all, :params => {:limit => 10})
  end

end
