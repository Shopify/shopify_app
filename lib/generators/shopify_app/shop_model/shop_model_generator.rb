require 'rails/generators/base'
require 'rails/generators/active_record'

module ShopifyApp
  module Generators
    class ShopModelGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      def create_shop_model
        copy_file 'shop.rb', 'app/models/shop.rb'
      end

      def create_shop_migration
        migration_template 'db/migrate/create_shops.erb', 'db/migrate/create_shops.rb'
      end

      def update_shopify_app_initializer
        gsub_file 'config/initializers/shopify_app.rb', 'ShopifyApp::InMemorySessionStore', 'Shop'
      end

      def create_shop_fixtures
        copy_file 'shops.yml', 'test/fixtures/shops.yml'
      end

      private

      def rails_migration_version
        Rails.version.match(/\d\.\d/)[0]
      end

      # for generating a timestamp when using `create_migration`
      def self.next_migration_number(dir)
        ActiveRecord::Generators::Base.next_migration_number(dir)
      end
    end
  end
end
