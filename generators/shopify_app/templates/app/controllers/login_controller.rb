class LoginController < ApplicationController
  def index
    # Ask user for their #{shop}.myshopify.com address
    
    # If the #{shop}.myshopify.com address is already provided in the URL, just skip to #authenticate
    if params[:shop].present?
      redirect_to :controller => 'login', :action => "authenticate", :shop => params[:shop]
    end
  end

  def authenticate
    if params[:shop].present?
      redirect_to ShopifyAPI::Session.new(params[:shop].to_s).create_permission_url
    else
      redirect_to return_address
    end
  end
  
  # Shopify redirects the logged-in user back to this action along with
  # the authorization token t.
  # 
  # This token is later combined with the developer's shared secret to form
  # the password used to call API methods.
  def finalize
    shopify_session = ShopifyAPI::Session.new(params[:shop], params[:t], params)
    if shopify_session.valid?
      session[:shopify] = shopify_session
      flash[:notice] = "Logged in to shopify store."
      
      redirect_to return_address
      session[:return_to] = nil
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
  
  protected
  
  def return_address
    session[:return_to] || root_url
  end
end