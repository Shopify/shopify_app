class LoginController < ApplicationController

  def index
  end

  def authenticate
    redirect_to ShopifyAPI::Session.new(params[:shop]).create_permission_url    
  end

  def finalize
    shopify_session = ShopifyAPI::Session.new(params[:shop], params[:t])
    if shopify_session.valid?
      session[:shopify] = shopify_session
      flash[:notice] = "Logged in to shopify store."
      redirect_to '/dashboard'
    else
      flash[:error] = "Could log in to shopify store."
      redirect_to :action => 'index'
    end
  end
  
  def logout
    session[:shopify] = nil
    flash[:notice] = "Successfully logged out."
    
    redirect_to :action => 'index'    
  end  
  
  
end