# frozen_string_literal: true

module ShopifyApp
  # Performs login after OAuth completes
  class CallbackController < ActionController::Base
    include ShopifyApp::LoginProtection
    include ShopifyApp::EnsureBilling

    def callback
      begin
        session, cookie = validated_auth_objects
      rescue
        return respond_with_error
      end

      save_session(session) if session
      update_rails_cookie(session, cookie)

      return respond_with_user_token_flow if start_user_token_flow?(session)

      perform_post_authenticate_jobs(session)
      respond_successfully if check_billing(session)
    end

    private

    def save_session(session)
      return true # FIXME - update tests to properly mock this boundary
      ShopifyApp::SessionRepository.store_session(session)
    end

    def validated_auth_objects
      filtered_params = request.parameters.symbolize_keys.slice(:code, :shop, :timestamp, :state, :host, :hmac)

      oauth_payload = ShopifyAPI::Auth::Oauth.validate_auth_callback(
        cookies: {
          ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME =>
            cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME],
        },
        auth_query: ShopifyAPI::Auth::Oauth::AuthQuery.new(**filtered_params),
      )
      session = oauth_payload.dig(:session)
      cookie = oauth_payload.dig(:cookie)

      [session, cookie]
    end

    def update_rails_cookie(session, cookie)
      if cookie.value.present?
        cookies.encrypted[cookie.name] = {
          expires: cookie.expires,
          secure: true,
          http_only: true,
          value: cookies.value,
        }
      end

      session[:shopify_user_id] = session.associated_user.associated_user.id if session.online?
    end

    def respond_successfully
      if ShopifyAPI::Context.embedded?
        return_to = session.delete(:return_to) || ""
        redirect_to(ShopifyAPI::Auth.embedded_app_url(params[:host]) + return_to, allow_other_host: true)
      else
        redirect_to(return_address)
      end
    end

    def respond_with_error
      flash[:error] = I18n.t("could_not_log_in")
      redirect_to(login_url_with_optional_shop)
    end

    def respond_with_user_token_flow
      redirect_to(login_url_with_optional_shop)
    end

    def start_user_token_flow?(shopify_session)
      return false unless ShopifyApp::SessionRepository.user_storage.present?
      return false if shopify_session.online?

      update_user_access_scopes?
    end

    def update_user_access_scopes?
      return true if session[:shopify_user_id].nil?

      user_access_scopes_strategy.update_access_scopes?(shopify_user_id: session[:shopify_user_id])
    end

    def user_access_scopes_strategy
      ShopifyApp.configuration.user_access_scopes_strategy
    end

    def perform_post_authenticate_jobs(session)
      install_webhooks(session)
      install_scripttags(session)
      perform_after_authenticate_job(session)
    end

    def install_webhooks(session)
      return unless ShopifyApp.configuration.has_webhooks?

      WebhooksManager.queue(session.shop, session.access_token)
    end

    def install_scripttags(session)
      return unless ShopifyApp.configuration.has_scripttags?

      ScripttagsManager.queue(
        session.shop,
        session.access_token,
        ShopifyApp.configuration.scripttags,
      )
    end

    def perform_after_authenticate_job(session)
      config = ShopifyApp.configuration.after_authenticate_job

      return unless config && config[:job].present?

      job = config[:job]
      job = job.constantize if job.is_a?(String)

      if config[:inline] == true
        job.perform_now(shop_domain: session.shop)
      else
        job.perform_later(shop_domain: session.shop)
      end
    end
  end
end
