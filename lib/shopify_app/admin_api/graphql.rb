module ShopifyApp
  module AdminAPI
    class GraphQL
      class << self
        include WithTokenRefetch

        def query(session:, **query_options)
          with_token_refetch(session) do
            client = ShopifyAPI::Clients::Graphql::Admin.new(session:)
            client.query(**query_options)
          end
        end
      end
    end
  end
end
