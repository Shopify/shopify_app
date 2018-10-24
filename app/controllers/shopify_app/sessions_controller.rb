module ShopifyApp
  class SessionsController < ActionController::Base
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
      validate_shop
    end

    def top_level_interaction
      @url = login_url(top_level: true)
      validate_shop
    end

    def granted_storage_access
      return unless validate_shop

      session['shopify.granted_storage_access'] = true

      params = { shop: @shop }
      redirect_to "#{ShopifyApp.configuration.root_url}?#{params.to_query}"
    end

    def callback
      if auth_hash
        login_shop
        install_webhooks
        install_scripttags
        perform_after_authenticate_job

        redirect_to return_address
      else
        flash[:error] = I18n.t('could_not_log_in')
        redirect_to login_url
      end
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

    def login_shop
      sess = ShopifyAPI::Session.new(shop_name, token)

      request.session_options[:renew] = true
      session.delete(:_csrf_token)
      session[:shopify] = ShopifyApp::SessionRepository.store(sess)
      session[:shopify_domain] = shop_name
      session[:shopify_user] = associated_user if associated_user.present?
    end

    def auth_hash
      request.env['omniauth.auth']
    end

    def shop_name
      auth_hash.uid
    end

    def associated_user
      return unless auth_hash['extra'].present?
      auth_hash['extra']['associated_user']
    end

    def token
      auth_hash['credentials']['token']
    end

    def install_webhooks
      return unless ShopifyApp.configuration.has_webhooks?

      WebhooksManager.queue(
        shop_name,
        token,
        ShopifyApp.configuration.webhooks
      )
    end

    def install_scripttags
      return unless ShopifyApp.configuration.has_scripttags?

      ScripttagsManager.queue(
        shop_name,
        token,
        ShopifyApp.configuration.scripttags
      )
    end

    def perform_after_authenticate_job
      config = ShopifyApp.configuration.after_authenticate_job

      return unless config && config[:job].present?

      if config[:inline] == true
        config[:job].perform_now(shop_domain: session[:shopify_domain])
      else
        config[:job].perform_later(shop_domain: session[:shopify_domain])
      end
    end

    def return_address
      session.delete(:return_to) || ShopifyApp::configuration.root_url
    end
  end
end
