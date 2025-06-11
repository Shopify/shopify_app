# frozen_string_literal: true

module ShopifyApp
  module Auth
    class TokenExchange
      attr_reader :auth_result, :id_token

      # For backwards compatibility, support both old and new interfaces
      def self.perform(id_token: nil, auth_result: nil)
        if auth_result
          new(auth_result: auth_result).perform_with_auth_result
        else
          new(id_token: id_token).perform_with_id_token
        end
      end

      def initialize(id_token: nil, auth_result: nil)
        @id_token = id_token
        @auth_result = auth_result
      end

      # New method that uses pre-authenticated result
      def perform_with_auth_result
        handle_token_exchange(auth_result)
      end

      # Legacy method that performs authentication
      def perform_with_id_token
        request_hash = build_exchange_request
        config = build_auth_config

        auth_result = ::ShopifyApp::AuthAdminEmbedded.authenticate(request_hash, config)

        case auth_result["action"]
        when "proceed_or_exchange"
          handle_token_exchange(auth_result)
        else
          raise_exchange_error(auth_result)
        end
      end

      private

      def build_exchange_request
        {
          "method" => "POST",
          "headers" => {
            "Authorization" => "Bearer #{id_token}",
            "Content-Type" => "application/json",
          },
          "body" => "",
          "url" => "#{ShopifyApp.configuration.host}/token_exchange",
        }
      end

      def build_auth_config
        {
          "client_id" => ShopifyApp.configuration.api_key,
          "client_secret" => ShopifyApp.configuration.secret,
          "app_origin" => ShopifyApp.configuration.host,
          "login_path" => ShopifyApp.configuration.login_url,
          "patch_session_token_path" => "#{ShopifyApp.configuration.root_url}/patch_shopify_id_token",
          "exit_iframe_path" => "/exit_iframe",
        }
      end

      def handle_token_exchange(auth_result)
        jwt_payload = auth_result["jwt"]["object"]
        domain = jwt_payload["dest"]&.gsub(%r{^https://}, "")

        Logger.info("Performing Token Exchange for [#{domain}]")

        # Exchange offline token
        offline_session = perform_exchange(auth_result["exchange"]["offline"], jwt_payload, online: false)
        SessionRepository.store_session(offline_session)

        # Exchange online token if configured
        if online_token_configured?
          Logger.info("Performing Token Exchange for [#{domain}] - (Online)")
          online_session = perform_exchange(auth_result["exchange"]["online"], jwt_payload, online: true)
          SessionRepository.store_session(online_session)
        end

        # Run post-authenticate tasks with the appropriate session
        session = online_token_configured? ? online_session : offline_session
        ShopifyApp.configuration.post_authenticate_tasks.perform(session)

        session
      rescue ActiveRecord::RecordNotUnique
        Logger.debug("Session not stored due to concurrent token exchange calls")
        session
      rescue ActiveRecord::RecordInvalid => e
        if e.message.include?("has already been taken")
          Logger.debug("Session not stored due to concurrent token exchange calls")
          session
        else
          raise
        end
      rescue => error
        Logger.error("An error occurred during the token exchange: [#{error.class}] #{error.message}")
        raise
      end

      def perform_exchange(exchange_config, jwt_payload, online:)
        exchange_request = exchange_config["req"]

        # Perform the HTTP request
        uri = URI(exchange_request["url"])
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        exchange_request["headers"].each { |k, v| request[k] = v }
        request.body = exchange_request["body"]

        response = http.request(request)

        if response.code == "200"
          build_session_from_response(JSON.parse(response.body), jwt_payload, online: online)
        else
          Logger.error("Token exchange failed with status #{response.code}: #{response.body}")
          raise ShopifyApp::Errors::HttpResponseError.new(
            response: { status: response.code.to_i, body: response.body },
          )
        end
      end

      def build_session_from_response(response_data, jwt_payload, online:)
        shop = jwt_payload["dest"]&.gsub(%r{^https://}, "")

        session_id = ShopifyApp::SessionUtils.session_id_from_jwt_payload(
          payload: jwt_payload,
          online: online,
        )

        # Build a proper ShopifyAPI::Session object
        session = ShopifyAPI::Auth::Session.new(
          id: session_id,
          shop: shop,
          access_token: response_data["access_token"],
          scope: response_data["scope"],
          expires: response_data["expires_in"] ? Time.now + response_data["expires_in"].to_i : nil,
          is_online: online,
        )

        if online && jwt_payload["sub"]
          session.shopify_user_id = jwt_payload["sub"]
        end

        session
      end

      def raise_exchange_error(auth_result)
        case auth_result["action"]
        when "invalid_id_token"
          Logger.error("Invalid id token during token exchange")
          raise ShopifyApp::Errors::InvalidJwtTokenError
        when "invalid_shop", "missing_shop"
          Logger.error("Invalid or missing shop during token exchange")
          raise ShopifyApp::Errors::MissingShopDomainError
        else
          Logger.error("Token exchange failed: #{auth_result["action"]}")
          raise ShopifyApp::Errors::TokenExchangeError.new(
            "Token exchange failed with action: #{auth_result["action"]}",
          )
        end
      end

      def online_token_configured?
        ShopifyApp.configuration.online_token_configured?
      end
    end
  end
end
