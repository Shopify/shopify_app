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
    attr_accessor :log_level

    # customise urls
    attr_accessor :root_url
    attr_writer :login_url
    attr_writer :login_callback_url
    attr_accessor :embedded_redirect_url

    # customise ActiveJob queue names
    attr_accessor :scripttags_manager_queue_name
    attr_accessor :webhooks_manager_queue_name

    # configure myshopify domain for local shopify development
    attr_accessor :myshopify_domain

    # ability to have webpacker installed but not used in this gem and the generators
    attr_accessor :disable_webpacker

    # allow namespacing webhook jobs
    attr_accessor :webhook_jobs_namespace

    # takes a ShopifyApp::BillingConfiguration object
    attr_accessor :billing

    def initialize
      @root_url = "/"
      @myshopify_domain = "myshopify.com"
      @scripttags_manager_queue_name = Rails.application.config.active_job.queue_name
      @webhooks_manager_queue_name = Rails.application.config.active_job.queue_name
      @disable_webpacker = ENV["SHOPIFY_APP_DISABLE_WEBPACKER"].present?
    end

    def login_url
      @login_url || File.join(@root_url, "login")
    end

    def login_callback_url
      # Not including @root_url to keep historic behaviour
      @login_callback_url || File.join("auth/shopify/callback")
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

    def user_access_scopes_strategy=(class_name)
      unless class_name.is_a?(String)
        raise ConfigurationError, "Invalid user access scopes strategy - expected a string"
      end

      @user_access_scopes_strategy = class_name.safe_constantize
    end

    def user_access_scopes_strategy
      return @user_access_scopes_strategy if @user_access_scopes_strategy

      return ShopifyApp::AccessScopes::NoopStrategy unless reauth_on_access_scope_changes

      ShopifyApp::AccessScopes::UserStrategy
    end

    def has_webhooks?
      webhooks.present?
    end

    def has_scripttags?
      scripttags.present?
    end

    def requires_billing?
      billing.present?
    end

    def shop_access_scopes
      @shop_access_scopes || scope
    end

    def user_access_scopes
      @user_access_scopes || scope
    end
  end

  class BillingConfiguration
    INTERVAL_ONE_TIME = "ONE_TIME"
    INTERVAL_EVERY_30_DAYS = "EVERY_30_DAYS"
    INTERVAL_ANNUAL = "ANNUAL"

    attr_reader :charge_name
    attr_reader :amount
    attr_reader :currency_code
    attr_reader :interval

    def initialize(charge_name:, amount:, interval:, currency_code: "USD")
      @charge_name = charge_name
      @amount = amount
      @currency_code = currency_code
      @interval = interval
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
