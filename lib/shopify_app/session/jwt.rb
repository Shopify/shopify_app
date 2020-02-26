module ShopifyApp
  class JWT
    def initialize(token_data)
      @payload, @header = token_data
    end

    def payload
      return unless @payload['aud'] == ShopifyApp.configuration.api_key
      return unless @payload['exp'].to_i >= Time.now.to_i
      return unless @payload['nbf'].to_i <= Time.now.to_i

      @payload
    end
  end
end
