
  protected

  def shop
    @shop ||= Shop.find_by(id: session[:shopify])
  end
  helper_method :shop
