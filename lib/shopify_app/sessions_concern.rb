module ShopifyApp
  module SessionsConcern
    extend ActiveSupport::Concern

    included do
      include ShopifyApp::LoginProtection
    end

    def new
      authenticate if params[:shop].present?
    end

    def create
      authenticate
    end

    def callback
      if auth_hash
        login_shop
        install_webhooks
        install_scripttags

        flash[:notice] = I18n.t('.logged_in')
        redirect_to_with_fallback return_address
      else
        flash[:error] = I18n.t('could_not_log_in')
        redirect_to_with_fallback login_url
      end
    end

    def destroy
      session[:shopify] = nil
      session[:shopify_domain] = nil
      flash[:notice] = I18n.t('.logged_out')
      redirect_to_with_fallback login_url
    end

    protected

    def authenticate
      if shop_name = sanitize_shop_param(params)
        fullpage_redirect_to "#{main_app.root_path}auth/shopify?shop=#{shop_name}"
      else
        redirect_to_with_fallback return_address
      end
    end

    def login_shop
      sess = ShopifyAPI::Session.new(shop_name, token)
      session[:shopify] = ShopifyApp::SessionRepository.store(sess)
      session[:shopify_domain] = shop_name
    end

    def auth_hash
      request.env['omniauth.auth']
    end

    def shop_name
      auth_hash.uid
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

    def return_address
      session.delete(:return_to) || main_app.root_url
    end

    def sanitized_shop_name
      @sanitized_shop_name ||= sanitize_shop_param(params)
    end

    def sanitize_shop_param(params)
      return unless params[:shop].present?
      ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end

  end
end
