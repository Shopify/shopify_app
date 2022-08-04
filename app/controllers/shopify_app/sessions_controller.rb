# frozen_string_literal: true

module ShopifyApp
  class SessionsController < ActionController::Base
    include ShopifyApp::LoginProtection

    layout false, only: :new

    after_action only: [:new, :create] do |controller|
      controller.response.headers.except!("X-Frame-Options")
    end

    def new
      authenticate if sanitized_shop_name.present?
    end

    def create
      authenticate
    end

    def top_level_interaction
      @url = login_url_with_optional_shop(top_level: true)
      validate_shop_presence
    end

    def destroy
      reset_session
      flash[:notice] = I18n.t(".logged_out")
      redirect_to(login_url_with_optional_shop)
    end

    private

    def authenticate
      return render_invalid_shop_error unless sanitized_shop_name.present?

      copy_return_to_param_to_session

      if ShopifyApp.configuration.embedded_redirect_url.present?
        if params[:embedded].present? && params[:embedded] == "1"
          redirect_for_embedded
        else
          start_oauth
        end
      elsif top_level?
        start_oauth
      else
        redirect_auth_to_top_level
      end
    end

    def start_oauth
      callback_url = ShopifyApp.configuration.login_callback_url.gsub(%r{^/}, "")

      auth_attributes = ShopifyAPI::Auth::Oauth.begin_auth(
        shop: sanitized_shop_name,
        redirect_path: "/#{callback_url}",
        is_online: user_session_expected?
      )
      cookies.encrypted[auth_attributes[:cookie].name] = {
        expires: auth_attributes[:cookie].expires,
        secure: true,
        http_only: true,
        value: auth_attributes[:cookie].value,
      }

      redirect_to(auth_attributes[:auth_route], allow_other_host: true)
    end

    def validate_shop_presence
      @shop = sanitized_shop_name
      unless @shop
        render_invalid_shop_error
        return false
      end

      true
    end

    def copy_return_to_param_to_session
      session[:return_to] = RedirectSafely.make_safe(params[:return_to], "/") if params[:return_to]
    end

    def render_invalid_shop_error
      flash[:error] = I18n.t("invalid_shop_url")
      redirect_to(return_address)
    end

    def top_level?
      return true unless ShopifyApp.configuration.embedded_app?

      !params[:top_level].nil?
    end

    def redirect_auth_to_top_level
      fullpage_redirect_to(login_url_with_optional_shop(top_level: true))
    end

    def redirect_for_embedded
      redirect_to(redirect_uri_for_embedded)
    end
  end
end
