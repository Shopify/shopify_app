require 'rails/generators/base'

module ShopifyApp
  module Generators
    class AddMarketingActivityExtensionGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def generate_app_extension
        template "marketing_activities_controller.rb", "app/controllers/marketing_activities_controller.rb"
        generate_routes
      end

      private

      def generate_routes
        inject_into_file(
          'config/routes.rb',
          optimize_indentation(routes, 2),
          after: "root :to => 'home#index'\n"
        )
      end

      def routes
        <<~EOS

          resource :marketing_activities, only: [:create, :update] do
            patch :resume
            patch :pause
            patch :delete
            post :republish
            post :preload_form_data
            post :preview
            post :errors
          end
        EOS
      end
    end
  end
end
