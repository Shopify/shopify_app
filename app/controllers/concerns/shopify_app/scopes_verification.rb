module ShopifyApp
  module ScopesVerification
    extend ActiveSupport::Concern
    include ScopeUtilities

    included do
      before_action do
        login_on_scope_changes(current_merchant_scopes, configuration_scopes)
      end
    end

    protected

    def current_merchant_scopes
      ShopifyApp::SessionRepository.retrieve_shop_scopes(current_shopify_domain)
    end

    def configuration_scopes
      ShopifyApp.configuration.scope
    end

    private

    def current_shopify_domain
      return if params[:shop].blank?
      @shopify_domain ||= ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end
  end
end
