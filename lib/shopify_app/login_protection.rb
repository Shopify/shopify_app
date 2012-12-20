module ShopifyApp::LoginProtection
  extend ActiveSupport::Concern
  
  included do
    rescue_from ActiveResource::UnauthorizedAccess, with: :close_session
  end
  
  def shopify_session
    if session[:shopify]
      begin
        # session[:shopify] set in LoginController#finalize
        ShopifyAPI::Base.activate_session(session[:shopify])
        yield
      ensure 
        ShopifyAPI::Base.clear_session
      end
    else
      session[:return_to] = request.fullpath if request.get?
      redirect_to login_path
    end
  end
  
  def shop_session
    session[:shopify]
  end
  
  protected
  
  def close_session
    session[:shopify] = nil
    redirect_to login_path
  end
end
