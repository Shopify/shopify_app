module ShopifyApp
  module LoginProtection
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveResource::UnauthorizedAccess, :with => :close_session
    end

    def shopify_session
      if shop_session
        begin
          # session[:shopify] set in LoginController#show
          ShopifyAPI::Base.activate_session(shop_session)
          yield
        ensure
          ShopifyAPI::Base.clear_session
        end
      else
        redirect_to_login
      end
    end

    def shop_session
      return unless session[:shopify]
      @shop_session ||= ShopifySessionRepository.retrieve(session[:shopify])
    end

    def login_again_if_different_shop
      if shop_session && params[:shop] && params[:shop].is_a?(String) && shop_session.url != params[:shop]
        redirect_to_login
      end
    end

    protected

    def redirect_to_login
      session[:return_to] = request.fullpath if request.get?
      redirect_to login_path(shop: params[:shop])
    end

    def close_session
      session[:shopify] = nil
      redirect_to login_path
    end

  end
end
