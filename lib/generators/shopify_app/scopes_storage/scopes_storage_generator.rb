# frozen_string_literal: true
require 'rails/generators/base'
require 'rails/generators/active_record'

module ShopifyApp
  module Generators
    class ScopesStorageGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      class_option :with_cookie_authentication, type: :boolean, default: false
      class_option :embedded, type: :string, default: 'true'

      def create_scopes_storage_in_shop_model
        if yes?("Do you want to add scopes column to the Shop model? [y/n]")
          migration_template('db/migrate/add_scopes_column.erb', 'db/migrate/add_scopes_column.rb')
          copy_file('shop_with_scopes.rb', 'app/models/shop.rb')
        end
      end

      def include_scopes_verification_in_home_controller
        template('home_controller.rb', 'app/controllers/home_controller.rb') unless with_cookie_authentication?
      end

      private

      def embedded?
        options['embedded'] == 'true'
      end

      def embedded_app?
        ShopifyApp.configuration.embedded_app?
      end

      def with_cookie_authentication?
        options['with_cookie_authentication']
      end

      def rails_migration_version
        Rails.version.match(/\d\.\d/)[0]
      end

      class << self
        private :next_migration_number

        # for generating a timestamp when using `create_migration`
        def next_migration_number(dir)
          ActiveRecord::Generators::Base.next_migration_number(dir)
        end
      end
    end
  end
end
