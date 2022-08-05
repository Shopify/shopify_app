# frozen_string_literal: true

module ShopifyApp
  # Performs login after OAuth completes
  class CallbackController < ActionController::Base
    include ShopifyApp::LoginProtection
    include ShopifyApp::EnsureBilling

    def callback
      begin
        filtered_params = request.parameters.symbolize_keys.slice(:code, :shop, :timestamp, :state, :host, :hmac)

        auth_result = ShopifyAPI::Auth::Oauth.validate_auth_callback(
          cookies: {
            ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME =>
              cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME],
          },
          auth_query: ShopifyAPI::Auth::Oauth::AuthQuery.new(**filtered_params)
        )
      rescue
        return respond_with_error
      end

      cookies.encrypted[auth_result[:cookie].name] = {
        expires: auth_result[:cookie].expires,
        secure: true,
        http_only: true,
        value: auth_result[:cookie].value,
      }

      session[:shopify_user_id] = auth_result[:session].associated_user.id if auth_result[:session].online?

      if start_user_token_flow?(auth_result[:session])
        return respond_with_user_token_flow
      end

      perform_post_authenticate_jobs(auth_result[:session])
      has_payment = check_billing(auth_result[:session])

      respond_successfully if has_payment
    end

    private

    def respond_successfully
      if ShopifyAPI::Context.embedded?
        # TODO: replace this param with ShopifyAPI::Auth.embedded_app_url or whatever the new
        # method name will be, once https://github.com/Shopify/shopify-api-ruby/pull/1002 is merged
        redirect_to(embedded_app_url(params[:host]), allow_other_host: true)
      else
        redirect_to(return_address)
      end
    end

    # TODO: remove this once https://github.com/Shopify/shopify-api-ruby/pull/1002
    # is merged and released
    def embedded_app_url(host)
      decoded_host = Base64.decode64(host)
      "https://#{decoded_host}/apps/#{ShopifyAPI::Context.api_key}"
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
        ShopifyApp.configuration.scripttags
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
