require 'rails/generators/base'

module ShopifyApp
  module Generators
    class RoutesGenerator < Rails::Generators::Base

       def add_routes
        route_without_newline "root :to => 'home#index'"
        route "end"
        route_without_newline "  delete 'logout' => :destroy"
        route_without_newline "  get 'auth/shopify/callback' => :callback"
        route_without_newline "  post 'login' => :create"
        route_without_newline "  get 'login' => :new"
        route_without_newline "controller :sessions do"
        route "get 'design' => 'home#design'"
        route_without_newline "get 'welcome' => 'home#welcome'"
      end

      private

      def route_without_newline(routing_code)
        sentinel = /\.routes\.draw do(?:\s*\|map\|)?\s*$/
        inject_into_file 'config/routes.rb', "\n  #{routing_code}", { after: sentinel, verbose: false }
      end

    end
  end
end
