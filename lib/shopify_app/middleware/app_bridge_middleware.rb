# frozen_string_literal: true
module ShopifyApp
  class AppBridgeMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      if request.params.has_key?("shop") && !request.params.has_key?("host")
        shop = request.params["shop"]
        host = Base64.urlsafe_encode64("#{shop}/admin", padding: false)
        request.update_param("host", host)
      end

      @app.call(env)
    end
  end
end
