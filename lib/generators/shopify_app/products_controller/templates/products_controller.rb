# frozen_string_literal: true

class ProductsController < AuthenticatedController
  def index
    @products = ShopifyAPI::Product.find(:all, params: { limit: 10 })
    render(json: { products: @products.map(&:as_json) })
  end
end
