require 'rails/generators/base'
require 'rails/generators/active_record'

module ShopifyApp
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)
      attr_reader :opts

      def initialize(args, *options)
        @opts = Hash[options.first.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/)]
        super(args, *options)
      end

      def create_shopify_app_initializer
        template 'shopify_app.rb', 'config/initializers/shopify_app.rb'
      end

      def create_and_inject_into_omniauth_initializer
        unless File.exist? "config/initializers/omniauth.rb"
          copy_file 'omniauth.rb', 'config/initializers/omniauth.rb'
        end

        inject_into_file(
          'config/initializers/omniauth.rb',
          File.read(File.expand_path(find_in_source_paths('shopify_provider.rb'))),
          after: "Rails.application.config.middleware.use OmniAuth::Builder do\n"
        )
      end

      def create_shopify_session_repository_initializer
        copy_file 'shopify_session_repository.rb', 'config/initializers/shopify_session_repository.rb'
      end

      def inject_embedded_app_options_to_application
        if embedded_app?
          application "config.action_dispatch.default_headers.delete('X-Frame-Options')"
          application "config.action_dispatch.default_headers['P3P'] = 'CP=\"Not used\"'"
        end
      end

      def inject_into_application_controller
        inject_into_class(
          "app/controllers/application_controller.rb",
          'ApplicationController',
          "  include ShopifyApp::Controller\n"
        )
      end

      def create_embedded_app_layout
        if embedded_app?
          copy_file 'embedded_app.html.erb', 'app/views/layouts/embedded_app.html.erb'
        end
      end

      def create_home_controller
        template 'home_controller.rb', 'app/controllers/home_controller.rb'
      end

      def create_home_index_view
        copy_file 'index.html.erb', 'app/views/home/index.html.erb'
        if embedded_app?
          prepend_to_file(
            'app/views/home/index.html.erb',
            File.read(File.expand_path(find_in_source_paths('shopify_app_ready_script.html')))
          )
        end
      end

      def add_home_index_route
        route "root :to => 'home#index'"
      end

      private

      def embedded_app?
        opts[:embedded] != 'false'
      end

    end
  end
end
