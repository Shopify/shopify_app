# ShopifyApp::AdminAPI::REST::HTTPClient

module ShopifyApp
  module AdminAPI
    module REST
      module RequestErrorHandling
        def request(session:, **options)
          with_token_refetch(session) do
            super(session:, **options)
          end
        end
      end
    end
  end
end
