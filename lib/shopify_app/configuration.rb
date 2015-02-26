module ShopifyApp
  class Configuration

    # Shopify App settings. These values should match the configuration
    # for the app in your Shopify Partners page. Change your settings in
    # `config/initializers/shopify_app.rb`
    attr_accessor :api_key
    attr_accessor :secret
    attr_accessor :embedded_app
    alias_method  :embedded_app?, :embedded_app

    def initialize
      @api_key = ENV["SHOPIFY_APP_API_KEY"]
      @secret =  ENV["SHOPIFY_APP_SECRET"]
      @embedded_app = true
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
end
