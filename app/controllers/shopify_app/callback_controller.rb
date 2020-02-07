# frozen_string_literal: true

module ShopifyApp
  # Performs login after OAuth completes
  class CallbackController < ActionController::Base
    include ShopifyApp::LoginProtection

    def callback
      if auth_hash
        login_shop

        if ShopifyApp::SessionRepository.user_storage.present? && user_session.blank?
          return redirect_to(login_url_with_optional_shop)
        end

        install_webhooks
        install_scripttags
        perform_after_authenticate_job

        redirect_to return_address
      else
        flash[:error] = I18n.t('could_not_log_in')
        redirect_to(login_url_with_optional_shop)
      end
    end

    private

    def login_shop
      reset_session_options
      set_shopify_session
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

    def reset_session_options
      request.session_options[:renew] = true
      session.delete(:_csrf_token)
    end

    def set_shopify_session
      session_store = ShopifyAPI::Session.new(
        domain: shop_name,
        token: token,
        api_version: ShopifyApp.configuration.api_version
      )

      session[:shopify_user] = associated_user
      if session[:shopify_user].present?
        session[:user_id] = ShopifyApp::SessionRepository.store_user_session(session_store, associated_user)
      else
        session[:shop_id] = ShopifyApp::SessionRepository.store_shop_session(session_store)
      end
      session[:shopify_domain] = shop_name
      session[:user_session] = auth_hash&.extra&.session
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

      job = config[:job]
      job = job.constantize if job.is_a?(String)

      if config[:inline] == true
        job.perform_now(shop_domain: session[:shopify_domain])
      else
        job.perform_later(shop_domain: session[:shopify_domain])
      end
    end
  end
end
