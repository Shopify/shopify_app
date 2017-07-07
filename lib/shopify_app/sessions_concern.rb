module ShopifyApp
  module SessionsConcern
    extend ActiveSupport::Concern

    included do
      include ShopifyApp::LoginProtection
      layout false, only: :new
    end

    def new
      authenticate if sanitized_shop_name.present?
    end

    def create
      authenticate
    end

    def callback
      if auth_hash
        login_shop
        install_webhooks
        install_scripttags
        perform_after_authenticate_actions

        redirect_to return_address
      else
        flash[:error] = I18n.t('could_not_log_in')
        redirect_to login_url
      end
    end

    def destroy
      session[:shopify] = nil
      session[:shopify_domain] = nil
      flash[:notice] = I18n.t('.logged_out')
      redirect_to login_url
    end

    protected

    def authenticate
      if sanitized_shop_name.present?
        fullpage_redirect_to "#{main_app.root_path}auth/shopify?shop=#{sanitized_shop_name}"
      else
        redirect_to return_address
      end
    end

    def login_shop
      sess = ShopifyAPI::Session.new(shop_name, token)
      session[:shopify] = ShopifyApp::SessionRepository.store(sess)
      session[:shopify_domain] = shop_name

      perform_after_install_actions
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

    def perform_after_install_actions
      return unless ShopifyApp.configuration.enable_after_install_actions

      Shopify::AfterInstallJob.perform_later(shop_domain: session[:shopify_domain])
    end

    def perform_after_authenticate_actions
      return unless ShopifyApp.configuration.enable_after_authenticate_actions

      Shopify::AfterAuthenticateJob.perform_later(shop_domain: session[:shopify_domain])
    end
  end
end
