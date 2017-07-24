module ShopifyApp
  class SessionsController < ActionController::Base
    include ShopifyApp::LoginProtection
    layout false, only: :new

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
        perform_after_authenticate_job

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

    private

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
