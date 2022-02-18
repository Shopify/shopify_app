# frozen_string_literal: true

class ProductsController < AuthenticatedController
  def index
    products = ShopifyAPI::Clients::Rest::Admin.new.get(path: "products", query: { limit: 10 }).body
    render(json: products)
  end
end
