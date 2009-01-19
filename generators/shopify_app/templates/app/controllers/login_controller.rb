class LoginController < ApplicationController
  layout 'empty'
  
  def index
    # Ask user for their #{shop}.myshopify.com address
    # (Set up your view so that "awesome-store.myshopify.com" comes back in params[:shop])
  end

  def authenticate
    redirect_to ShopifyAPI::Session.new(params[:shop]).create_permission_url
  end

  def finalize
    shopify_session = ShopifyAPI::Session.new(params[:shop], params[:t])
    if shopify_session.valid?
      session[:shopify] = shopify_session
      flash[:notice] = "Logged in to shopify store."
      
      return_address = session[:return_to] || '/home'
      session[:return_to] = nil
      redirect_to return_address
    else
      flash[:error] = "Could not log in to Shopify store."
      redirect_to :action => 'index'
    end
  end
  
  def logout
    session[:shopify] = nil
    flash[:notice] = "Successfully logged out."
    
    redirect_to :action => 'index'
  end
end 