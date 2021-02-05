# frozen_string_literal: true

module ShopifyApp
  module ScopesVerification
    extend ActiveSupport::Concern
    include ScopeUtilities

    included do
      before_action do
        login_on_scope_changes(granted_access_scopes, configured_access_scopes)
      end
    end

    protected

    def login_on_scope_changes(current_merchant_scopes, configuration_scopes)
      redirect_to(shop_login) if scopes_configuration_mismatch?(current_merchant_scopes, configuration_scopes)
    end

    def granted_access_scopes
      begin
        # The "real work" should go here
        installed_access_scopes
      ensure
        ShopifyAPI::Base.clear_session
      end
    end

    def configured_access_scopes
      ShopifyApp.configuration.scope
    end

    private

    def installed_access_scopes
      # This is identical to LoginProtection right now
      shop_session = ShopifyApp::SessionRepository.retrieve_shop_session_by_shopify_domain(current_shopify_domain)
      ShopifyAPI::Base.activate_session(shop_session)

      client = ShopifyAPI::GraphQL.client(ShopifyApp.configuration.api_version)

      # This is the real work
      result = client.query(client.parse(installation_query))

      # This looks like a ScopeUtilities method
      result.data.app_installation.access_scopes.map { |access_scope| access_scope.handle }
    end

    def installation_query
      query = <<-GRAPHQL
        {
          appInstallation {
            accessScopes {
              handle
            }
          }
        }
      GRAPHQL
    end

    def current_shopify_domain
      return if params[:shop].blank?
      ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end

    def shop_login
      ShopifyApp::Utils.shop_login_url(shop: params[:shop], return_to: request.fullpath)
    end
  end
end
