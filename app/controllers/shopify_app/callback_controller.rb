# frozen_string_literal: true

module ShopifyApp
  # Performs login after OAuth completes
  class CallbackController < ActionController::Base
    include ShopifyApp::LoginProtection

    def callback
      return respond_with_error if invalid_request?

      store_access_token_and_build_session

      if start_user_token_flow?
        return respond_with_user_token_flow
      end

      perform_post_authenticate_jobs

      respond_successfully
    end

    private

    def respond_successfully
      if jwt_request?
        head(:ok)
      else
        redirect_to(return_address)
      end
    end

    def respond_with_user_token_flow
      redirect_to(login_url_with_optional_shop)
    end

    def store_access_token_and_build_session
      if native_browser_request?
        reset_session_options
      end
      set_shopify_session
    end

    def invalid_request?
      return true unless auth_hash

      jwt_request? && !valid_jwt_auth?
    end

    def native_browser_request?
      !jwt_request?
    end

    def perform_post_authenticate_jobs
      install_webhooks
      install_scripttags
      perform_after_authenticate_job
    end

    def respond_with_error
      if jwt_request?
        head(:unauthorized)
      else
        flash[:error] = I18n.t('could_not_log_in')
        redirect_to(login_url_with_optional_shop)
      end
    end

    # Override user_session_by_cookie from LoginProtection to bypass allow_cookie_authentication
    # setting check because session cookies are justified at top level
    def user_session_by_cookie
      return unless session[:user_id].present?
      ShopifyApp::SessionRepository.retrieve_user_session(session[:user_id])
    end

    def start_user_token_flow?
      if jwt_request?
        false
      else
        ShopifyApp::SessionRepository.user_storage.present? && user_session.blank?
      end
    end

    def jwt_request?
      jwt_shopify_domain || jwt_shopify_user_id
    end

    def valid_jwt_auth?
      auth_hash && jwt_shopify_domain == shop_name && jwt_shopify_user_id == associated_user_id
    end

    def auth_hash
      request.env['omniauth.auth']
    end

    def shop_name
      auth_hash.uid
    end

    def offline_access_token
      ShopifyApp::SessionRepository.retrieve_shop_session_by_shopify_domain(shop_name)&.token
    end

    def online_access_token
      ShopifyApp::SessionRepository.retrieve_user_session_by_shopify_user_id(associated_user_id)&.token
    end

    def associated_user
      return unless auth_hash.dig('extra', 'associated_user').present?

      auth_hash['extra']['associated_user'].merge('scope' => auth_hash['extra']['associated_user_scope'])
    end

    def associated_user_id
      associated_user && associated_user['id']
    end

    def token
      auth_hash['credentials']['token']
    end

    def shop_scopes
      return unless auth_hash['extra']['scope']
      ShopifyAPI::ApiAccess.new(auth_hash['extra']['scope'])
    end

    def reset_session_options
      request.session_options[:renew] = true
      session.delete(:_csrf_token)
    end

    def set_shopify_session
      session_store = ShopifyAPI::Session.new(
        domain: shop_name,
        token: token,
        api_version: ShopifyApp.configuration.api_version,
        extra: { scopes: shop_scopes }
      )

      session[:shopify_user] = associated_user
      if session[:shopify_user].present?
        session[:shop_id] = nil if shop_session && shop_session.domain != shop_name
        session[:user_id] = ShopifyApp::SessionRepository.store_user_session(session_store, associated_user)
      else
        session[:shop_id] = ShopifyApp::SessionRepository.store_shop_session(session_store)
        session[:user_id] = nil if user_session && user_session.domain != shop_name
      end
      session[:shopify_domain] = shop_name
      session[:user_session] = auth_hash&.extra&.session
    end

    def install_webhooks
      return unless ShopifyApp.configuration.has_webhooks?

      WebhooksManager.queue(
        shop_name,
        offline_access_token || online_access_token,
        ShopifyApp.configuration.webhooks
      )
    end

    def install_scripttags
      return unless ShopifyApp.configuration.has_scripttags?

      ScripttagsManager.queue(
        shop_name,
        offline_access_token || online_access_token,
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
