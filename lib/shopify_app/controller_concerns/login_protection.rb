module ShopifyApp
  module LoginProtection
    extend ActiveSupport::Concern

    class ShopifyDomainNotFound < StandardError; end

    included do
      after_action :set_test_cookie
      rescue_from ActiveResource::UnauthorizedAccess, :with => :close_session
    end

    def shopify_session
      return redirect_to_login unless shop_session
      clear_top_level_oauth_cookie

      begin
        ShopifyAPI::Base.activate_session(shop_session)
        yield
      ensure
        ShopifyAPI::Base.clear_session
      end
    end

    def shop_session
      return unless session[:shopify]
      @shop_session ||= ShopifyApp::SessionRepository.retrieve(session[:shopify])
    end

    def login_again_if_different_shop
      if shop_session && params[:shop] && params[:shop].is_a?(String) && (shop_session.url != params[:shop])
        clear_shop_session
        redirect_to_login
      end
    end

    def redirect_to_request_storage_access
      render :request_storage_access, layout: false, locals: {
        doesNotHaveStorageAccessUrl: top_level_interaction_path(shop: sanitized_shop_name),
        hasStorageAccessUrl: login_url(top_level: true),
        appHomeUrl: granted_storage_access_path,
        current_shopify_domain: current_shopify_domain,
      }
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

    def login_url(top_level: false)
      url = ShopifyApp.configuration.login_url

      query_params = login_url_params(top_level: top_level)

      url = "#{url}?#{query_params.to_query}" if query_params.present?
      url
    end

    def login_url_params(top_level:)
      query_params = {}
      query_params[:shop] = sanitized_params[:shop] if params[:shop].present?

      has_referer_shop_name = referer_sanitized_shop_name.present?

      if has_referer_shop_name
        query_params[:shop] ||= referer_sanitized_shop_name
      end

      query_params[:top_level] = true if top_level
      query_params
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

    def referer_sanitized_shop_name
      return unless request.referer.present?

      @referer_sanitized_shop_name ||= begin
        referer_uri = URI(request.referer)
        query_params = Rack::Utils.parse_query(referer_uri.query)

        sanitize_shop_param(query_params.with_indifferent_access)
      end
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

    def set_test_cookie
      return unless ShopifyApp.configuration.embedded_app?
      return unless userAgentCanPartitionCookies
      session['shopify.cookies_persist'] = true
    end

    def clear_top_level_oauth_cookie
      session.delete('shopify.top_level_oauth')
    end

    def set_top_level_oauth_cookie
      session['shopify.top_level_oauth'] = true
    end

    def userAgentCanPartitionCookies
      request.user_agent.match(/Version\/12\.0\.?\d? Safari/)
    end
  end
end
