module ShopifyApp
  module LoginProtection
    extend ActiveSupport::Concern

    class ShopifyDomainNotFound < StandardError; end

    included do
      rescue_from ActiveResource::UnauthorizedAccess, :with => :close_session
    end

    def shopify_session
      if shop_session
        begin
          ShopifyAPI::Base.activate_session(shop_session)
          yield
        ensure
          ShopifyAPI::Base.clear_session
        end
      else
        # A fullpage redirect is needed in order for the session to be set correctly
        if session['been_here_before']
          redirect_to_login
        else
          session['been_here_before'] = true
          fullpage_redirect_to login_url
        end
      end
    end

    def shop_session
      session[:francine] = 'Hello'      
      return unless session[:shopify]
      @shop_session ||= ShopifyApp::SessionRepository.retrieve(session[:shopify])
    end

    def login_again_if_different_shop
      if shop_session && params[:shop] && params[:shop].is_a?(String) && (shop_session.url != params[:shop])
        clear_shop_session
        redirect_to_login
      end
    end

    protected

    def redirect_to_login
      if request.xhr?
        head :unauthorized
      else
        if request.get?
          session[:return_to] = "#{request.path}?#{sanitized_params.to_query}"
        end
        redirect_to login_url
      end
    end

    def close_session
      clear_shop_session
      redirect_to login_url
    end

    def clear_shop_session
      session[:shopify] = nil
      session[:shopify_domain] = nil
      session[:shopify_user] = nil
    end

    def login_url
      url = ShopifyApp.configuration.login_url

      if params[:shop].present?
        query = { shop: sanitized_params[:shop] }.to_query
        url = "#{url}?#{query}"
      end

      url
    end

    def fullpage_redirect_to(url)
      if ShopifyApp.configuration.embedded_app?
        render 'shopify_app/shared/redirect', layout: false, locals: { url: url, current_shopify_domain: current_shopify_domain }
      else
        redirect_to url
      end
    end

    def current_shopify_domain
      shopify_domain = sanitized_shop_name || session[:shopify_domain]
      return shopify_domain if shopify_domain.present?

      raise ShopifyDomainNotFound
    end

    def sanitized_shop_name
      @sanitized_shop_name ||= sanitize_shop_param(params)
    end

    def sanitize_shop_param(params)
      return unless params[:shop].present?
      ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end

    def sanitized_params
      request.query_parameters.clone.tap do |query_params|
        if params[:shop].is_a?(String)
          query_params[:shop] = sanitize_shop_param(params)
        end
      end
    end
  end
end
