# frozen_string_literal: true

require "rails/generators/base"

module ShopifyApp
  module Generators
    class AppProxyControllerGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def create_app_proxy_controller
        template("app_proxy_controller.rb", "app/controllers/app_proxy_controller.rb")
      end

      def create_app_proxy_index_view
        copy_file("index.html.erb", "app/views/app_proxy/index.html.erb")
      end

      def add_app_proxy_route
        inject_into_file(
          "config/routes.rb",
          File.read(File.expand_path(find_in_source_paths("app_proxy_route.rb"))),
          after: "mount ShopifyApp::Engine, at: '/'\n"
        )
      end
    end
  end
end
