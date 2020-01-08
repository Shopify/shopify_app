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
    attr_accessor :embedded_app
    alias_method  :embedded_app?, :embedded_app
    attr_accessor :webhooks
    attr_accessor :scripttags
    attr_accessor :after_authenticate_job
    attr_reader :session_repository
    attr_accessor :api_version

    # customise urls
    attr_accessor :root_url
    attr_accessor :login_url

    # customise ActiveJob queue names
    attr_accessor :scripttags_manager_queue_name
    attr_accessor :webhooks_manager_queue_name

    # configure myshopify domain for local shopify development
    attr_accessor :myshopify_domain

    # ability to have webpacker installed but not used in this gem and the generators
    attr_accessor :disable_webpacker

    # allow namespacing webhook jobs
    attr_accessor :webhook_jobs_namespace

    def initialize
      @root_url = '/'
      @myshopify_domain = 'myshopify.com'
      @scripttags_manager_queue_name = Rails.application.config.active_job.queue_name
      @webhooks_manager_queue_name = Rails.application.config.active_job.queue_name
      @disable_webpacker = ENV['SHOPIFY_APP_DISABLE_WEBPACKER'].present?
    end

    def login_url
      @login_url || File.join(@root_url, 'login')
    end

    def session_repository=(klass)
      @session_repository = klass
      ShopifyApp::SessionRepository.storage = klass
    end

    def has_webhooks?
      webhooks.present?
    end

    def has_scripttags?
      scripttags.present?
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
