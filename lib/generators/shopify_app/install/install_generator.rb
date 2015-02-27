require 'rails/generators/base'
require 'rails/generators/active_record'

module ShopifyApp
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      argument :api_key, type: :string, required: false
      argument :secret,  type: :string, required: false
      argument :scope,   type: :string, required: false

      class_option :embedded_app, type: :boolean, default: true, desc: 'pass false to create a regular app'

      def create_shopify_app_initializer
        initializer "shopify_app.rb" do
"ShopifyApp.configure do |config|
  config.api_key = '#{options[:api_key]}'
  config.secret = '#{options[:secret]}'
  config.scope = '#{options[:scope] || 'read_orders, read_products'}'
  config.embedded_app = #{options[:embedded_app]}
end"
        end
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

      def add_embedded_app_options_to_application
        if options[:embedded_app]
          application "config.action_dispatch.default_headers.delete('X-Frame-Options')"
          application "config.action_dispatch.default_headers['P3P'] = 'CP=\"Not used\"'"
        end
      end

      def inject_into_application_controller
        inject_into_class(
          "app/controllers/application_controller.rb",
          ApplicationController,
          "  include ShopifyApp::Controller\n"
        )
      end

      def create_embedded_app_layout
        if options[:embedded_app]
          copy_file 'embedded_app.html.erb', 'app/views/layouts/embedded_app.html.erb'
        end
      end

      def create_home_controller
        copy_file 'home_controller.rb', 'app/controllers/home_controller.rb'
        if options[:embedded_app]
          inject_into_file(
          'app/controllers/home_controller.rb',
          "  layout 'embedded_app'\n",
          after: "around_filter :shopify_session\n"
        )
        end
      end

      def create_home_index_view
        copy_file 'index.html.erb', 'app/views/home/index.html.erb'
        if options[:embedded_app]
          append_to_file('app/views/home/index.html.erb') do <<-'SCRIPT'
<script type="text/javascript">
  ShopifyApp.ready(function(){
    ShopifyApp.Bar.initialize({
      title: "Home",
      icon: "<%= asset_path('faveicon.png') %>"
    });
  });
</script>
          SCRIPT
          end
        end
      end

      def add_home_index_route
        route "root :to => 'home#index'"
      end

    end
  end
end
