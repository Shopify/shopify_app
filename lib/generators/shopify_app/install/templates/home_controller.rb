class HomeController < AuthenticatedController
<% if embedded_app? -%>
  layout 'embedded_app'
<% end -%>

  def index
    @products = ShopifyAPI::Product.find(:all, :params => {:limit => 10})
  end

end
