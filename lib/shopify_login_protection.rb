module ShopifyLoginProtection

  def shopify_session
    if session[:shopify]
      begin
        ActiveResource::Base.site = session[:shopify].site
        yield
      ensure 
        ActiveResource::Base.site = nil
      end
    else            
      session[:return_to] = request.path
      redirect_to :controller => 'login'      
    end
  end
  
  def current_shop
    session[:shopify]
  end
    
end