# frozen_string_literal: true
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
      class_option :with_cookie_authentication, type: :boolean, default: false

      def create_shopify_app_initializer
        @application_name = format_array_argument(options['application_name'])
        @scope = format_array_argument(options['scope'])
        @api_version = options['api_version'] || ShopifyAPI::Meta.admin_versions.find(&:latest_supported).handle

        template('shopify_app.rb', 'config/initializers/shopify_app.rb')
      end

      def create_session_store_initializer
        copy_file('session_store.rb', 'config/initializers/session_store.rb')
      end

      def create_and_inject_into_omniauth_initializer
        unless File.exist?("config/initializers/omniauth.rb")
          copy_file('omniauth.rb', 'config/initializers/omniauth.rb')
        end

        return if !Rails.env.test? && shopify_provider_exists?

        inject_into_file(
          'config/initializers/omniauth.rb',
          File.read(File.expand_path(find_in_source_paths('shopify_provider.rb'))),
          after: "Rails.application.config.middleware.use(OmniAuth::Builder) do\n"
        )
      end

      def create_embedded_app_layout
        return unless embedded_app?

        copy_file('embedded_app.html.erb', 'app/views/layouts/embedded_app.html.erb')
        copy_file('_flash_messages.html.erb', 'app/views/layouts/_flash_messages.html.erb')

        if ShopifyApp.use_webpacker?
          copy_file('shopify_app.js', 'app/javascript/shopify_app/shopify_app.js')
          copy_file('flash_messages.js', 'app/javascript/shopify_app/flash_messages.js')
          copy_file('shopify_app_index.js', 'app/javascript/shopify_app/index.js')
          append_to_file('app/javascript/packs/application.js', "require(\"shopify_app\")\n")
        else
          copy_file('shopify_app.js', 'app/assets/javascripts/shopify_app.js')
          copy_file('flash_messages.js', 'app/assets/javascripts/flash_messages.js')
        end
      end

      def create_user_agent_initializer
        template('user_agent.rb', 'config/initializers/user_agent.rb')
      end

      def mount_engine
        route("mount ShopifyApp::Engine, at: '/'")
      end

      def insert_hosts_into_development_config
        inject_into_file(
          'config/environments/development.rb',
          "  config.hosts = (config.hosts rescue []) << /\\w+\\.ngrok\\.io/\n",
          after: "Rails.application.configure do\n"
        )
      end

      private

      def shopify_provider_exists?
        File.open("config/initializers/omniauth.rb") do |file|
          file.each_line do |line|
            if line =~ /provider :shopify/
              puts "\e[33m#{omniauth_warning}\e[0m"
              return true
            end
          end
        end
        false
      end

      def omniauth_warning
        <<~OMNIAUTH
          \n[WARNING] The Shopify App generator attempted to add the following Shopify Omniauth \
          provider 'config/initializers/omniauth.rb':

          \e[0m#{shopify_provider_template}\e[33m

          Consider updating 'config/initializers/omniauth.rb' to match the configuration above.
        OMNIAUTH
      end

      def shopify_provider_template
        File.read(File.expand_path(find_in_source_paths('shopify_provider.rb')))
      end

      def embedded_app?
        options['embedded'] == 'true'
      end

      def format_array_argument(array)
        array.join(' ').tr('"', '')
      end

      def with_cookie_authentication?
        options['with_cookie_authentication'] || !embedded_app?
      end
    end
  end
end
