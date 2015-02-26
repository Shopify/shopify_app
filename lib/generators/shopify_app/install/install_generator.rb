require 'rails/generators/base'
require 'rails/generators/active_record'

module ShopifyApp
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      def create_shopify_app_initializer
        copy_file 'shopify_app.rb', 'config/initializers/shopify_app.rb'
      end

      def create_and_inject_into_omniauth_initializer
        unless File.exist? "config/initializers/omniauth.rb"
          copy_file 'omniauth.rb', 'config/initializers/omniauth.rb'
        end

        inject_into_file(
          'config/initializers/omniauth.rb',
          after: "Rails.application.config.middleware.use OmniAuth::Builder do\n"
        ) do <<-'RUBY'

  provider :shopify,
    ShopifyApp.configuration.api_key,
    ShopifyApp.configuration.secret,

    :scope => ShopifyApp.configuration.scope,

    :setup => lambda {|env|
       params = Rack::Utils.parse_query(env['QUERY_STRING'])
       site_url = "https://#{params['shop']}"
       env['omniauth.strategy'].options[:client_options][:site] = site_url
    }

        RUBY
        end
      end

      def create_shopify_session_repository_initializer
        copy_file 'shopify_session_repository.rb', 'config/initializers/shopify_session_repository.rb'
      end

      def inject_into_application_controller
        inject_into_class(
          "app/controllers/application_controller.rb",
          ApplicationController,
          "  include ShopifyApp::Controller\n"
        )
      end

      def create_home_controller
        copy_file 'home_controller.rb', 'app/controllers/home_controller.rb'
      end

      def create_home_index_view
        copy_file 'index.html.erb', 'app/views/home/index.html.erb'
      end

      def add_home_index_route
        route "root :to => 'home#index'"
      end

    end
  end
end
