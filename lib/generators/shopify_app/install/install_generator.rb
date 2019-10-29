require 'rails/generators/base'

module ShopifyApp
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      class_option :application_name, type: :array, default: ['My', 'Shopify', 'App']
      class_option :scope, type: :array, default: ['read_products']
      class_option :embedded, type: :string, default: 'true'
      class_option :api_version, type: :string, default: nil

      def add_dotenv_gem
        gem('dotenv-rails', group: [:test, :development])
      end

      def create_shopify_app_initializer
        @application_name = format_array_argument(options['application_name'])
        @scope = format_array_argument(options['scope'])
        @api_version = options['api_version'] || ShopifyAPI::Meta.admin_versions.find(&:latest_supported).handle

        template 'shopify_app.rb', 'config/initializers/shopify_app.rb'
      end

      def create_session_store_initializer
        copy_file('session_store.rb', 'config/initializers/session_store.rb')
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

      def create_embedded_app_layout
        return unless embedded_app?
        if ShopifyApp.rails6?
          copy_file 'embedded_app.html.erb', 'app/views/layouts/embedded_app.html.erb'
          copy_file '_flash_messages.html.erb', 'app/views/layouts/_flash_messages.html.erb'

          copy_file('shopify_app.js', 'app/javascript/shopify_app/shopify_app.js')
          copy_file('flash_messages.js', 'app/javascript/shopify_app/flash_messages.js')
          copy_file('shopify_app_index.js', 'app/javascript/shopify_app/index.js')

          %w(
            itp_helper
            partition_cookies
            redirect
            storage_access
            storage_access_redirect
            top_level_interaction
          ).each do |filename|
            copy_file(
              "../../../../../app/assets/javascripts/shopify_app/#{filename}.js",
              "app/javascript/shopify_app/#{filename}.js",
            )
          end

          copy_file('redirect.js', 'app/javascript/packs/shopify_app_redirect.js')
          copy_file('enable_cookies.js', 'app/javascript/packs/shopify_app_enable_cookies.js')
          copy_file('request_storage_access.js', 'app/javascript/packs/shopify_app_request_storage_access.js')
          copy_file('top_level.js', 'app/javascript/packs/shopify_app_top_level.js')
          append_to_file('app/javascript/packs/application.js', 'require("shopify_app")')
        else
          copy_file 'embedded_app.html.erb', 'app/views/layouts/embedded_app.html.erb'
          copy_file('shopify_app.js', 'app/assets/javascripts/shopify_app.js')
          copy_file '_flash_messages.html.erb', 'app/views/layouts/_flash_messages.html.erb'
          copy_file('flash_messages.js', 'app/assets/javascripts/flash_messages.js')
        end
      end

      def create_user_agent_initializer
        template 'user_agent.rb', 'config/initializers/user_agent.rb'
      end

      def mount_engine
        route "mount ShopifyApp::Engine, at: '/'"
      end

      def insert_hosts_into_development_config
        inject_into_file(
          'config/environments/development.rb',
          "  config.hosts << /\\h+.ngrok.io/\n",
          after: "Rails.application.configure do\n"
        )
      end

      private

      def embedded_app?
        options['embedded'] == 'true'
      end

      def format_array_argument(array)
        array.join(' ').tr('"', '')
      end
    end
  end
end
