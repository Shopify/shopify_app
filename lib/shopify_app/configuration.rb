module ShopifyApp
  class Configuration

    # Shopify App settings. These values should match the configuration
    # for the app in your Shopify Partners page. Change your settings in
    # `config/initializers/shopify_app.rb`
    attr_accessor :api_key
    attr_accessor :secret
    attr_accessor :scope
    attr_accessor :embedded_app
    alias_method  :embedded_app?, :embedded_app
    attr_accessor :webhooks
    attr_accessor :scripttags

    # customise ActiveJob queue names
    attr_accessor :scripttags_manager_queue_name
    attr_accessor :webhooks_manager_queue_name

    # configure myshopify domain for local shopify development
    attr_accessor :myshopify_domain

    def initialize
      @myshopify_domain = 'myshopify.com'
    end

    def has_webhooks?
      webhooks.present?
    end

    def has_scripttags?
      scripttags.present?
    end

    def scripttags_manager_queue_name
      @scripttags_manager_queue_name ||= Rails.application.config.active_job.queue_name
    end

    def webhooks_manager_queue_name
      @webhooks_manager_queue_name ||= Rails.application.config.active_job.queue_name
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
