require 'rails/generators/base'
require 'rails/generators/active_record'

module ShopifyApp
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      class_option :api_key, type: :string, default: '<api_key>'
      class_option :secret, type: :string, default: '<secret>'
      class_option :scope, type: :string, default: 'read_orders, read_products'
      class_option :embedded, type: :string, default: 'true'

      def create_shopify_app_initializer
        @api_key = options['api_key']
        @secret = options['secret']
        @scope = options['scope']

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
          "  include ShopifyApp::LoginProtection\n"
        )
      end

      def create_embedded_app_layout
        if embedded_app?
          copy_file 'embedded_app.html.erb', 'app/views/layouts/embedded_app.html.erb'
          copy_file '_flash_messages.html.erb', 'app/views/layouts/_flash_messages.html.erb'
        end
      end

      def mount_engine
        route "mount ShopifyApp::Engine, at: '/'"
      end

      private

      def embedded_app?
        options['embedded'] == 'true'
      end
    end
  end
end
