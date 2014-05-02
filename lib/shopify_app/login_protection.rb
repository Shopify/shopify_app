module ShopifyApp::LoginProtection
  extend ActiveSupport::Concern
  
  included do
    rescue_from ActiveResource::UnauthorizedAccess, :with => :close_session
  end
  
  def shopify_session
    if session[:shopify]
      begin
        # session[:shopify] set in LoginController#show
        ShopifyAPI::Base.activate_session(YAML.load(session[:shopify]))
        yield
      ensure 
        ShopifyAPI::Base.clear_session
      end
    else
      session[:return_to] = request.fullpath if request.get?
      redirect_to login_path(shop: params[:shop])
    end
  end
  
  def shop_session
    session[:shopify] && YAML.load(session[:shopify])
  end

  def login_again_if_different_shop
    if shop_session && params[:shop] && params[:shop].is_a?(String) && shop_session.url != params[:shop]
      redirect_to login_path(shop: params[:shop]) 
    end  
  end
  
  protected
  
  def close_session
    session[:shopify] = nil
    redirect_to login_path
  end
end
