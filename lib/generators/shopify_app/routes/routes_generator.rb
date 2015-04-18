require 'rails/generators/base'

module ShopifyApp
  module Generators
    class RoutesGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def inject_shopify_app_routes_into_application_routes
        route(session_routes)
      end

      def disable_engine_routes
        inject_into_file(
          'config/initializers/shopify_app.rb',
          "  config.routes = false\n",
          before: 'end'
        )
      end

      private

      def session_routes
        File.read(routes_file_path)
      end

      def routes_file_path
        File.expand_path(find_in_source_paths('routes.rb'))
      end
    end
  end
end
