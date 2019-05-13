module ShopifyApp
  class SessionsController < ActionController::Base # rubocop:disable Metrics/ClassLength
    include ShopifyApp::LoginProtection

    layout false, only: :new
    after_action only: [:new, :create] do |controller|
      controller.response.headers.except!('X-Frame-Options')
    end

    def new
      authenticate if sanitized_shop_name.present?
    end

    def create
      authenticate
    end

    def enable_cookies
      return unless validate_shop

      render(:enable_cookies, layout: false, locals: {
        does_not_have_storage_access_url: top_level_interaction_path(
          shop: sanitized_shop_name
        ),
        has_storage_access_url: login_url(top_level: true),
        app_home_url: granted_storage_access_path(shop: sanitized_shop_name),
        current_shopify_domain: current_shopify_domain,
      })
    end

    def top_level_interaction
      @url = login_url(top_level: true)
      validate_shop
    end

    def granted_storage_access
      return unless validate_shop

      session['shopify.granted_storage_access'] = true

      params = { shop: @shop }
      redirect_to("#{return_address}?#{params.to_query}")
    end

    def destroy
      reset_session
      flash[:notice] = I18n.t('.logged_out')
      redirect_to login_url
    end

    private

    def authenticate
      return render_invalid_shop_error unless sanitized_shop_name.present?
      session['shopify.omniauth_params'] = { shop: sanitized_shop_name }

      if user_agent_can_partition_cookies
        authenticate_with_partitioning
      else
        authenticate_normally
      end
    end

    def authenticate_normally
      if request_storage_access?
        redirect_to_request_storage_access
      elsif authenticate_in_context?
        authenticate_in_context
      else
        authenticate_at_top_level
      end
    end

    def authenticate_with_partitioning
      if session['shopify.cookies_persist']
        clear_top_level_oauth_cookie
        authenticate_in_context
      else
        set_top_level_oauth_cookie
        fullpage_redirect_to enable_cookies_path(shop: sanitized_shop_name)
      end
    end

    def validate_shop
      @shop = sanitized_shop_name
      unless @shop
        render_invalid_shop_error
        return false
      end

      true
    end

    def render_invalid_shop_error
      flash[:error] = I18n.t('invalid_shop_url')
      redirect_to return_address
    end

    def authenticate_in_context
      redirect_to "#{main_app.root_path}auth/shopify"
    end

    def authenticate_at_top_level
      fullpage_redirect_to login_url(top_level: true)
    end

    def authenticate_in_context?
      return true unless ShopifyApp.configuration.embedded_app?
      params[:top_level]
    end

    def request_storage_access?
      return false unless ShopifyApp.configuration.embedded_app?
      return false if params[:top_level]
      return false if user_agent_is_mobile
      return false if user_agent_is_pos

      !session['shopify.granted_storage_access']
    end

    def redirect_to_request_storage_access
      render :request_storage_access, layout: false, locals: {
        does_not_have_storage_access_url: top_level_interaction_path(
          shop: sanitized_shop_name
        ),
        has_storage_access_url: login_url(top_level: true),
        app_home_url: granted_storage_access_path(shop: sanitized_shop_name),
        current_shopify_domain: current_shopify_domain
      }
    end
  end
end
