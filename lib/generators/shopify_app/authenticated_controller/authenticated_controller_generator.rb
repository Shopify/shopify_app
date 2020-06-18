# frozen_string_literal: true

require 'rails/generators/base'

module ShopifyApp
  module Generators
    class AuthenticatedControllerGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def create_authenticated_controller
        template('authenticated_controller.rb', 'app/controllers/authenticated_controller.rb')
      end
    end
  end
end
