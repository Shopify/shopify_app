# frozen_string_literal: true

module ShopifyApp
  # Performs login after OAuth completes
  class CallbackController < ActionController::Base
    include ShopifyApp::InstallLifecycle
    include ShopifyApp::LoginProtection

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

    private

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
  end
end
