# frozen_string_literal: true

module ShopifyApp
  module TokenExchange
    extend ActiveSupport::Concern
    include ShopifyApp::AdminAPI::WithTokenRefetch
    include ShopifyApp::SanitizedParams
    include ShopifyApp::EmbeddedApp

    included do
      include ShopifyApp::WithShopifyIdToken
    end

    INVALID_SHOPIFY_ID_TOKEN_ERRORS = [
      ShopifyApp::Errors::MissingJwtTokenError,
      ShopifyApp::Errors::InvalidJwtTokenError,
    ].freeze

    def activate_shopify_session(&block)
      auth_result = authenticate_with_admin_embedded
      
      # Store the JWT payload from auth result for use by WithShopifyIdToken methods
      if auth_result["jwt"] && auth_result["jwt"]["object"]
        @jwt_payload = auth_result["jwt"]["object"]
        @shopify_id_token = auth_result["jwt"]["string"]
      end
      
      case auth_result["action"]
      when "proceed_or_exchange"
        handle_successful_auth(auth_result, &block)
      when "redirect_to_patch_session_token", "redirect_to_embedded", "exit_iframe"
        handle_auth_redirect(auth_result["response"])
      when "invalid_id_token", "invalid_shop", "missing_shop"
        handle_invalid_token(auth_result)
      else
        handle_auth_error(auth_result)
      end
    rescue *INVALID_SHOPIFY_ID_TOKEN_ERRORS => e
      respond_to_invalid_shopify_id_token(e)
    end

    def should_exchange_expired_token?
      ShopifyApp.configuration.check_session_expiry_date && current_shopify_session.expired?
    end

    def current_shopify_session
      return unless current_shopify_session_id

      @current_shopify_session ||= ShopifyApp::SessionRepository.load_session(current_shopify_session_id)
    end

    def current_shopify_session_id
      return @current_shopify_session_id if defined?(@current_shopify_session_id)
      
      # If we have JWT payload from authenticate, use it directly
      if defined?(@jwt_payload) && @jwt_payload
        @current_shopify_session_id = ShopifyApp::SessionUtils.session_id_from_jwt_payload(
          payload: @jwt_payload,
          online: online_token_configured?
        )
      else
        # Otherwise fall back to parsing the token
        @current_shopify_session_id = ShopifyApp::SessionUtils.session_id_from_shopify_id_token(
          id_token: shopify_id_token,
          online: online_token_configured?,
        )
      end
    end

    def current_shopify_domain
      # Try to get from JWT payload first (already validated by authenticate)
      if defined?(@jwt_payload) && @jwt_payload
        shop = @jwt_payload["dest"]&.gsub(%r{^https://}, "")
        return ::ShopifyApp::Utils.sanitize_shop_domain(shop)
      end
      
      sanitized_shop_name || current_shopify_session&.shop
    rescue *INVALID_SHOPIFY_ID_TOKEN_ERRORS => e
      respond_to_invalid_shopify_id_token(e)
    end

    private

    def authenticate_with_admin_embedded
      request_hash = {
        "method" => request.method,
        "headers" => convert_headers_to_hash(request.headers),
        "body" => request.body.read.to_s,
        "url" => request.original_url
      }
      
      config = {
        "client_id" => ShopifyApp.configuration.api_key,
        "client_secret" => ShopifyApp.configuration.secret,
        "app_origin" => "#{request.protocol}#{request.host_with_port}",
        "login_path" => ShopifyApp.configuration.login_url,
        "patch_session_token_path" => "#{ShopifyApp.configuration.root_url}/patch_shopify_id_token",
        "exit_iframe_path" => "/exit_iframe"
      }
      
      ::ShopifyApp::AuthAdminEmbedded.authenticate(request_hash, config)
    end
    
    def convert_headers_to_hash(headers)
      hash = {}
      headers.each { |key, value| hash[key] = value }
      hash
    end

    def handle_successful_auth(auth_result, &block)
      # Extract JWT info
      jwt_info = auth_result["jwt"]
      jwt_payload = jwt_info["object"]
      
      # Perform token exchange if needed
      if should_exchange_expired_token? || current_shopify_session.blank?
        # Use the refactored Auth::TokenExchange service
        session = ShopifyApp::Auth::TokenExchange.perform(auth_result: auth_result)
        @current_shopify_session = session
      end
      
      # Activate session
      ShopifyApp::SessionContext.activate_session(current_shopify_session)
      
      # Execute block with token refetch capability
      with_token_refetch(current_shopify_session, jwt_info["string"], &block)
    ensure
      ShopifyApp::SessionContext.deactivate_session
    end
    
    def handle_auth_redirect(response)
      case response["status"]
      when 302
        redirect_to response["headers"]["Location"], allow_other_host: true
      when 200
        # For HTML responses (patch session token, exit iframe)
        render html: response["body"].html_safe, 
               layout: false,
               content_type: response["headers"]["Content-Type"]
      end
    end
    
    def handle_invalid_token(auth_result)
      if request.headers["HTTP_AUTHORIZATION"].blank?
        if embedded?
          redirect_to_bounce_page
        else
          redirect_to_embed_app_in_admin
        end
      else
        response.set_header("X-Shopify-Retry-Invalid-Session-Request", 1)
        render(json: { errors: [{ message: :unauthorized }] }, status: :unauthorized)
      end
    end
    
    def handle_auth_error(auth_result)
      response_info = auth_result["response"]
      render json: { error: auth_result["action"] }, status: response_info["status"]
    end

    def redirect_to_bounce_page
      ShopifyApp::Logger.debug("Redirecting to bounce page for patching Shopify ID token")
      
      patch_shopify_id_token_url =
        "#{ShopifyApp::SessionContext.host}#{ShopifyApp.configuration.root_url}/patch_shopify_id_token"
      patch_shopify_id_token_params = request.query_parameters.except(:id_token)

      bounce_url = "#{request.path}?#{patch_shopify_id_token_params.to_query}"

      # App Bridge will trigger a fetch to the URL in shopify-reload, with a new session token in headers
      patch_shopify_id_token_params["shopify-reload"] = bounce_url

      redirect_to(
        "#{patch_shopify_id_token_url}?#{patch_shopify_id_token_params.to_query}",
        allow_other_host: true,
      )
    end

    def online_token_configured?
      ShopifyApp.configuration.online_token_configured?
    end

    def respond_to_invalid_shopify_id_token(error)
      ShopifyApp::Logger.debug("Responding to invalid Shopify ID token: #{error.message}")
      handle_invalid_token({ "action" => "invalid_id_token" })
    end

    def fullpage_redirect_to(url)
      raise ShopifyApp::ShopifyDomainNotFound if current_shopify_domain.nil?

      render(
        "shopify_app/shared/redirect",
        layout: false,
        locals: { url: url, current_shopify_domain: current_shopify_domain, is_iframe: embedded? },
      )
    end
  end
end
