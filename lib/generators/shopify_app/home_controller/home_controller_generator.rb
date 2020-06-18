# frozen_string_literal: true
require 'rails/generators/base'

module ShopifyApp
  module Generators
    class HomeControllerGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      class_option :with_session_token, type: :boolean, default: false

      def create_home_controller
        @with_session_token = options['with_session_token']

        template(home_controller_template, 'app/controllers/home_controller.rb')
      end

      def create_products_controller
        generate("shopify_app:products_controller") if with_session_token?
      end

      def create_home_index_view
        template('index.html.erb', 'app/views/home/index.html.erb')
      end

      def add_home_index_route
        route("root :to => 'home#index'")
      end

      private

      def embedded_app?
        ShopifyApp.configuration.embedded_app?
      end

      def with_session_token?
        @with_session_token
      end

      def home_controller_template
        with_session_token? ? 'unauthenticated_home_controller.rb' : 'home_controller.rb'
      end
    end
  end
end
