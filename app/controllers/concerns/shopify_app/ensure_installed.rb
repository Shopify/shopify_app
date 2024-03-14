# frozen_string_literal: true

module ShopifyApp
  module EnsureInstalled
    extend ActiveSupport::Concern
    include ShopifyApp::AuthorizationStrategy

    included do
      if defined?(ShopifyApp::LoginProtection) && ancestors.include?(ShopifyApp::LoginProtection)
        message = <<~EOS
          We detected the use of incompatible concerns (EnsureInstalled and LoginProtection) in #{name},
          which leads to unpredictable behavior. You cannot include both concerns in the same controller.
        EOS

        raise message
      end

      before_action :check_shop_domain
      before_action :check_shop_known
      before_action :validate_non_embedded_session
    end

    def current_shopify_domain
      if params[:shop].blank?
        ShopifyApp::Logger.info("Could not identify installed store from current_shopify_domain")
        return
      end

      @shopify_domain ||= ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
      ShopifyApp::Logger.info("Installed store:  #{@shopify_domain} - deduced from Shopify Admin params")
      @shopify_domain
    end

    def installed_shop_session
      @installed_shop_session ||= SessionRepository.retrieve_shop_session_by_shopify_domain(current_shopify_domain)
    end

    private

    def check_shop_domain
      redirect_to(ShopifyApp.configuration.login_url) unless current_shopify_domain
    end

    def check_shop_known
      @shop = installed_shop_session
      unless @shop
        begin_auth
      end
    end

    def validate_non_embedded_session
      return if loaded_directly_from_admin?

      client = ShopifyAPI::Clients::Rest::Admin.new(session: installed_shop_session)
      client.get(path: "shop")
    rescue ShopifyAPI::Errors::HttpResponseError => error
      ShopifyApp::Logger.info("Shop offline session no longer valid. Redirecting to OAuth install")
      begin_auth if error.code == 401
      raise error if error.code != 401
    end
  end
end
