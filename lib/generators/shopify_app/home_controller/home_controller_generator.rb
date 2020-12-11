# frozen_string_literal: true
require 'rails/generators/base'

module ShopifyApp
  module Generators
    class HomeControllerGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      class_option :with_cookie_authentication, type: :boolean, default: false
      class_option :embedded, type: :string, default: 'true'

      def create_home_controller
        @with_cookie_authentication = options['with_cookie_authentication']

        template(home_controller_template, 'app/controllers/home_controller.rb')
      end

      def create_products_controller
        generate("shopify_app:products_controller") unless with_cookie_authentication?
      end

      def create_home_index_view
        template('index.html.erb', 'app/views/home/index.html.erb')
      end

      def add_home_index_route
        route("root :to => 'home#index'")
      end

      private

      def embedded_app?
        ShopifyApp.configuration.embedded_app? || options['embedded'] == 'true'
      end

      def with_cookie_authentication?
        @with_cookie_authentication || !embedded_app?
      end

      def home_controller_template
        with_cookie_authentication? ? 'home_controller.rb' : 'unauthenticated_home_controller.rb'
      end
    end
  end
end
