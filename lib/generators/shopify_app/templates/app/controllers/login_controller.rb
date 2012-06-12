class LoginController < ApplicationController
  def index
    # Ask user for their #{shop}.myshopify.com address
    
    # If the #{shop}.myshopify.com address is already provided in the URL, just skip to #authenticate
    if params[:shop].present?
      redirect_to "/auth/shopify?shop=#{params[:shop].to_s.strip}"
    end
  end
  
  def finalize
    if response = request.env['omniauth.auth']
      sess = ShopifyAPI::Session.new(params['shop'], response['credentials']['token'])
      session[:shopify] = sess        
      flash[:notice] = "Logged in"
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
