module ShopifyApp
  module SessionsConcern
    extend ActiveSupport::Concern

    def new
      authenticate if params[:shop].present?
    end

    def create
      authenticate
    end

    def callback
      if response = request.env['omniauth.auth']
        shop_name = response.uid
        token = response['credentials']['token']

        sess = ShopifyAPI::Session.new(shop_name, token)
        session[:shopify] = ShopifyApp::SessionRepository.store(sess)
        session[:shopify_domain] = shop_name

        WebhooksManager.queue(shop_name, token) if ShopifyApp.configuration.has_webhooks?
        ScripttagsManager.queue(shop_name, token) if ShopifyApp.configuration.has_scripttags?

        flash[:notice] = I18n.t('.logged_in')
        redirect_to_with_fallback return_address
      else
        flash[:error] = "Could not log in to Shopify store."
        redirect_to_with_fallback login_url
      end
    end

    def destroy
      session[:shopify] = nil
      session[:shopify_domain] = nil
      flash[:notice] = "Successfully logged out."
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
