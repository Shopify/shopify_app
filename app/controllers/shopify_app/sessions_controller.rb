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

    # TODO: Find a way to remove duplication of enable_cookies and top_level_interaction code
    def enable_cookies
      validate_shop
    end

    def top_level_interaction
      validate_shop
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

      if request_storage_access?
        redirect_to_request_storage_access
      elsif redirect_for_cookie_access?
        fullpage_redirect_to enable_cookies_path(shop: sanitized_shop_name)
      elsif authenticate_in_context?
        authenticate_in_context
      else
        authenticate_at_top_level
      end
    end
    
    def validate_shop
      @shop = sanitized_shop_name
      render_invalid_shop_error unless @shop
    end

    def render_invalid_shop_error
      flash[:error] = I18n.t('invalid_shop_url')
      redirect_to return_address
    end

    def authenticate_in_context
      clear_top_level_oauth_cookie
      redirect_to "#{main_app.root_path}auth/shopify"
    end

    def authenticate_at_top_level
      set_top_level_oauth_cookie # Is this vestigal now?
      fullpage_redirect_to login_url(top_level: true)
    end

    def authenticate_in_context?
      return true unless ShopifyApp.configuration.embedded_app?
      return true if params[:top_level]
      session['shopify.top_level_oauth']
    end

    def redirect_for_cookie_access?
      return false unless ShopifyApp.configuration.embedded_app?
      return false if params[:top_level]
      return false if session['shopify.cookies_persist']
      return false if !userAgentCanPartitionCookies

      true
    end

    def request_storage_access?
      return false unless ShopifyApp.configuration.embedded_app?
      return false if params[:top_level]
      return false if session['shopify.granted_storage_access']
      return false if userAgentCanPartitionCookies

      true
    end

    def userAgentCanPartitionCookies
      request.user_agent.match(/Version\/12.0.?\d? Safari/)
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
