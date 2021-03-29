# frozen_string_literal: true

require "rails/generators/base"

module ShopifyApp
  module Generators
    class ProductsControllerGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def create_products_controller
        template("products_controller.rb", "app/controllers/products_controller.rb")
      end

      def add_products_route
        route("get '/products', :to => 'products#index'")
      end
    end
  end
end
