# frozen_string_literal: true
module ShopifyApp
  class Configuration
    # Shopify App settings. These values should match the configuration
    # for the app in your Shopify Partners page. Change your settings in
    # `config/initializers/shopify_app.rb`
    attr_accessor :application_name
    attr_accessor :api_key
    attr_accessor :secret
    attr_accessor :old_secret
    attr_accessor :scope
    attr_writer :shop_access_scopes
    attr_writer :user_access_scopes
    attr_accessor :embedded_app
    alias_method  :embedded_app?, :embedded_app
    attr_accessor :webhooks
    attr_accessor :scripttags
    attr_accessor :after_authenticate_job
    attr_accessor :api_version

    attr_accessor :reauth_on_access_scope_changes

    # customise urls
    attr_accessor :root_url
    attr_writer :login_url

    # customise ActiveJob queue names
    attr_accessor :scripttags_manager_queue_name
    attr_accessor :webhooks_manager_queue_name

    # configure myshopify domain for local shopify development
    attr_accessor :myshopify_domain

    # ability to have webpacker installed but not used in this gem and the generators
    attr_accessor :disable_webpacker

    # allow namespacing webhook jobs
    attr_accessor :webhook_jobs_namespace

    # allow enabling of same site none on cookies
    attr_writer :enable_same_site_none

    # allow enabling jwt headers for authentication
    attr_accessor :allow_jwt_authentication

    attr_accessor :allow_cookie_authentication

    def initialize
      @root_url = '/'
      @myshopify_domain = 'myshopify.com'
      @scripttags_manager_queue_name = Rails.application.config.active_job.queue_name
      @webhooks_manager_queue_name = Rails.application.config.active_job.queue_name
      @disable_webpacker = ENV['SHOPIFY_APP_DISABLE_WEBPACKER'].present?
      @allow_cookie_authentication = true
    end

    def login_url
      @login_url || File.join(@root_url, 'login')
    end

    def user_session_repository=(klass)
      ShopifyApp::SessionRepository.user_storage = klass
    end

    def user_session_repository
      ShopifyApp::SessionRepository.user_storage
    end

    def shop_session_repository=(klass)
      ShopifyApp::SessionRepository.shop_storage = klass
    end

    def shop_session_repository
      ShopifyApp::SessionRepository.shop_storage
    end

    def shop_access_scopes_strategy
      return ShopifyApp::AccessScopes::NoopStrategy unless reauth_on_access_scope_changes
      ShopifyApp::AccessScopes::ShopStrategy
    end

    def user_access_scopes_strategy
      return ShopifyApp::AccessScopes::NoopStrategy unless reauth_on_access_scope_changes
      ShopifyApp::AccessScopes::UserStrategy
    end

    def has_webhooks?
      webhooks.present?
    end

    def has_scripttags?
      scripttags.present?
    end

    def enable_same_site_none
      !Rails.env.test? && (@enable_same_site_none.nil? ? embedded_app? : @enable_same_site_none)
    end

    def shop_access_scopes
      @shop_access_scopes || scope
    end

    def user_access_scopes
      @user_access_scopes || scope
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(config)
    @configuration = config
  end

  def self.configure
    yield configuration
  end
end
