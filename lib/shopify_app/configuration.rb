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

    # use the built in session routes?
    attr_accessor :routes

    # configure myshopify domain for local shopify development
    attr_accessor :myshopify_domain

    def routes_enabled?
      @routes
    end

    def initialize
      @routes = true
      @myshopify_domain = 'myshopify.com'
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
