# frozen_string_literal: true
module ShopifyApp
  class SessionsController < ActionController::Base
    include ShopifyApp::LoginProtection

    layout false, only: :new

    after_action only: [:new, :create] do |controller|
      controller.response.headers.except!('X-Frame-Options')
    end

    def new
      if sanitized_shop_name.present?
        Rails.logger.debug("[ShopifyApp::SessionsController] Sanitized shop name present. Authenticating...")
        authenticate
      end
    end

    def create
      Rails.logger.debug("[ShopifyApp::SessionsController] Authenticating...")
      authenticate
    end

    def enable_cookies
      Rails.logger.debug("[ShopifyApp::SessionsController] Enabling cookies...")
      return unless validate_shop_presence

      render(:enable_cookies, layout: false, locals: {
        does_not_have_storage_access_url: top_level_interaction_path(
          shop: sanitized_shop_name,
          return_to: params[:return_to]
        ),
        has_storage_access_url: login_url_with_optional_shop(top_level: true),
        app_target_url: granted_storage_access_path(
          shop: sanitized_shop_name,
          return_to: params[:return_to]
        ),
        current_shopify_domain: current_shopify_domain,
      })
    end

    def top_level_interaction
      @url = login_url_with_optional_shop(top_level: true)
      validate_shop_presence
    end

    def granted_storage_access
      Rails.logger.debug("[ShopifyApp::SessionsController] Granted storage access.")
      return unless validate_shop_presence

      session['shopify.granted_storage_access'] = true

      copy_return_to_param_to_session

      redirect_to(return_address_with_params({ shop: @shop }))
    end

    def destroy
      Rails.logger.debug("[ShopifyApp::SessionsController] Resetting session.")
      reset_session
      flash[:notice] = I18n.t('.logged_out')
      redirect_to(login_url_with_optional_shop)
    end

    private

    def authenticate
      return render_invalid_shop_error unless sanitized_shop_name.present?
      session['shopify.omniauth_params'] = { shop: sanitized_shop_name }

      copy_return_to_param_to_session

      set_user_tokens_option

      if user_agent_can_partition_cookies
        Rails.logger.debug("[ShopifyApp::SessionsController] Authenticating with partitioning...")
        authenticate_with_partitioning
      else
        Rails.logger.debug("[ShopifyApp::SessionsController] Authenticating normally...")
        authenticate_normally
      end
    end

    def authenticate_normally
      if request_storage_access?
        Rails.logger.debug("[ShopifyApp::SessionsController] Redirecting to request storage access...")
        redirect_to_request_storage_access
      elsif authenticate_in_context?
        Rails.logger.debug("[ShopifyApp::SessionsController] Authenticating in context...")
        authenticate_in_context
      else
        Rails.logger.debug("[ShopifyApp::SessionsController] Authenticating at top level...")
        authenticate_at_top_level
      end
    end

    def authenticate_with_partitioning
      if session['shopify.cookies_persist']
        clear_top_level_oauth_cookie
        authenticate_in_context
      else
        set_top_level_oauth_cookie
        enable_cookie_access
      end
    end

    # rubocop:disable Lint/SuppressedException
    def set_user_tokens_option
      if shop_session.blank?
        Rails.logger.debug("[ShopifyApp::SessionsController] Shop session is blank.")
        session[:user_tokens] = false
        return
      end

      session[:user_tokens] = ShopifyApp::SessionRepository.user_storage.present?

      ShopifyAPI::Session.temp(
        domain: shop_session.domain,
        token: shop_session.token,
        api_version: shop_session.api_version
      ) do
        ShopifyAPI::Metafield.find(:token_validity_bogus_check)
      end
    rescue ActiveResource::UnauthorizedAccess
      session[:user_tokens] = false
    rescue StandardError
    end
    # rubocop:enable Lint/SuppressedException

    def validate_shop_presence
      @shop = sanitized_shop_name
      unless @shop
        Rails.logger.debug("[ShopifyApp::SessionsController] Invalid shop detected.")
        render_invalid_shop_error
        return false
      end

      true
    end

    def copy_return_to_param_to_session
      session[:return_to] = RedirectSafely.make_safe(params[:return_to], '/') if params[:return_to]
    end

    def render_invalid_shop_error
      flash[:error] = I18n.t('invalid_shop_url')
      redirect_to(return_address)
    end

    def enable_cookie_access
      fullpage_redirect_to(enable_cookies_path(
        shop: sanitized_shop_name,
        return_to: session[:return_to]
      ))
    end

    def authenticate_in_context
      redirect_to("#{main_app.root_path}auth/shopify")
    end

    def authenticate_at_top_level
      fullpage_redirect_to(login_url_with_optional_shop(top_level: true))
    end

    def authenticate_in_context?
      return true unless ShopifyApp.configuration.embedded_app?
      params[:top_level]
    end

    def request_storage_access?
      return false unless ShopifyApp.configuration.embedded_app?
      return false if params[:top_level]
      return false if user_agent_is_mobile
      return false if user_agent_is_pos

      !session['shopify.granted_storage_access']
    end

    def redirect_to_request_storage_access
      render(
        :request_storage_access,
        layout: false,
        locals: {
          does_not_have_storage_access_url: top_level_interaction_path(
            shop: sanitized_shop_name,
            return_to: session[:return_to]
          ),
          has_storage_access_url: login_url_with_optional_shop(top_level: true),
          app_target_url: granted_storage_access_path(
            shop: sanitized_shop_name,
            return_to: session[:return_to]
          ),
          current_shopify_domain: current_shopify_domain,
        }
      )
    end
  end
end
